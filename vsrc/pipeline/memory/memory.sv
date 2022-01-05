`ifndef __MEMORY_SV
`define __MEMORY_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "pipeline/memory/writedata.sv"
`include "pipeline/memory/readdata.sv"
`else

`endif

module memory 
	import common::*;
	import commit_pkg::*;#(
	parameter QLEN = 16
)(
	input logic clk, reset,
	input source_instr_t[2-1:0] srcs,
	output commit_instr_t[RMEM_WIDTH-1:0] read_commit,
	output commit_instr_t[WMEM_WIDTH-1:0] write_commit,
	output commit_instr_t[2-1:0] uncached_commit,

	/* Write to WriteBuffer */
	output wbuffer_wreq_t[WMEM_WIDTH-1:0] wbuffer_wreq,

	/* Read Request */
	output dbus_req_t[RMEM_WIDTH-1:0] dbus_rreq,

	/* Request to WriteBuffer */
	output wbuffer_rreq_t[RMEM_WIDTH-1:0] wbuffer_rreq,

	/* Reply from DBus */
	input dbus_resp_t[RMEM_WIDTH-1:0] dbus_rresp,

	/* Reply from WriteBuffer */
	input wbuffer_rresp_t[RMEM_WIDTH-1:0] wbuffer_rresp

);

	localparam type mpipe12_t = struct packed {
		// each op
		u1 valid;
		u1 read, write;
		u32 addr;
		u64 data;
		preg_addr_t dst;
		msize_t msize;
		strobe_t strobe;
		u1 mem_unsigned;
	};

	localparam type mpipe23_t = struct packed {
		// read
		u1 valid;
		u3 addr_off;
		preg_addr_t dst;
		msize_t msize;
		u1 mem_unsigned;

		// from writebuffer
		wbuffer_rresp_t wbuffer_rresp, prev;
	};

	localparam type mpipe34_t = struct packed {
		// read
		u1 valid;
		u3 addr_off;
		preg_addr_t dst;
		msize_t msize;
		u1 mem_unsigned;

		// from writebuffer
		wbuffer_rresp_t wbuffer_rresp;
	};

	/* Stage 1: Address Generation,
			Byte Write Transformation and 
			(Batched 2W2R FIFO) or Pass-through,
			uncached commit */
	u1[1:0] is_uncached;
	u32[1:0] addr;
	u64[1:0] wd;
	strobe_t [1:0] strobe;
	for (genvar i = 0; i < 2; i++) begin
		always_ff @(posedge clk) begin
			if (srcs[i].valid && addr[i] == 'h80003754) $display("%x %x %x", srcs[i].pc, srcs[i].d1, srcs[i].imm);
		end
		
	end
	

	/* Address Generation */
	for (genvar i = 0; i < 2; i++) begin
		assign addr[i] = srcs[i].d1 + srcs[i].imm;
	end

	/* Byte Write Transformation */
	for (genvar i = 0; i < 2; i++) begin
		writedata wd_inst (
			.addr(addr[i][2:0]),
			._wd(srcs[i].d2),
			.msize(srcs[i].ctl.msize),
			.wd(wd[i]),
			.strobe(strobe[i])
		);
	end
	
	// check uncached
	for (genvar i = 0; i < 2; i++) begin
		assign is_uncached[i] = ~srcs[i].d1[31];
	end

	/* Generate mpipe12 */
	mpipe12_t [2-1:0] mpipe12_pre;
	for (genvar i = 0; i < 2; i++) begin
		assign mpipe12_pre[i].valid = srcs[i].valid & ~is_uncached[i];
		assign mpipe12_pre[i].read = srcs[i].ctl.memread;
		assign mpipe12_pre[i].write = srcs[i].ctl.memwrite;
		assign mpipe12_pre[i].addr = addr[i];
		assign mpipe12_pre[i].data = wd[i];
		assign mpipe12_pre[i].dst = srcs[i].dst;
		assign mpipe12_pre[i].msize = srcs[i].ctl.msize;
		assign mpipe12_pre[i].strobe = strobe[i];
		assign mpipe12_pre[i].mem_unsigned = srcs[i].ctl.mem_unsigned;
		always_ff @(posedge clk) begin
			// if (mpipe12_pre[i].write && srcs[i].pc == 32'h80002664) $display("%x %x", srcs[i].d1, srcs[i].pc);
		end
		
	end
	
	mpipe12_t  [2-1:0] mpipe12_o, mpipe12, mpipe12_nxt;
	u1 empty;
	assign mpipe12_nxt = empty ? mpipe12_pre : mpipe12_o;

	batched_fifo #(.QLEN(QLEN), .DATA_WIDTH($bits(mpipe12_t) * 2)) fifo_inst (
		.clk, .reset,
		.data_i(mpipe12_pre),
		.data_o(mpipe12_o),
		.empty(empty),
		.full(),
		.wen((~empty | ~dbus_rresp[0].data_ok | ~dbus_rresp[1].data_ok) && (mpipe12_pre[0].valid || mpipe12_pre[1].valid)),
		.ren(dbus_rresp[0].data_ok && dbus_rresp[1].data_ok)
	);
	// Stage 1->2 Pipeline / uncached commit
	for (genvar i = 0; i < 2; i++) begin
		// uncached commit
		assign uncached_commit[i].valid = srcs[i].valid & is_uncached[i];
		assign uncached_commit[i].data = wd[i];
		assign uncached_commit[i].extra = {srcs[i].ctl.msize, strobe[i], addr[i], 1'b1};
		assign uncached_commit[i].dst = srcs[i].dst;

		always_ff @(posedge clk) begin
			if (reset) begin
				mpipe12[i].valid <= '0;
			end else if (dbus_rresp[0].data_ok && dbus_rresp[1].data_ok) begin
				mpipe12[i] <= mpipe12_nxt[i];
			end
		end
	end
	

	/* Stage 2.W: Write to WriteBuffer and Commit */

	for (genvar i = 0; i < WMEM_WIDTH; i++) begin
		assign wbuffer_wreq[i].valid =
		mpipe12[i].valid && mpipe12[i].write && dbus_rresp[0].data_ok && dbus_rresp[1].data_ok;
		assign wbuffer_wreq[i].msize = mpipe12[i].msize;
		assign wbuffer_wreq[i].strobe = mpipe12[i].strobe;
		assign wbuffer_wreq[i].addr = mpipe12[i].addr;
		assign wbuffer_wreq[i].data = mpipe12[i].data;
		always_ff @(posedge clk) begin
			if (wbuffer_wreq[i].valid) begin
				$display("addr%x", wbuffer_wreq[i].addr);
			end
		end
		
		always_ff @(posedge clk) begin
			// if (wbuffer_wreq[i].valid) $display("%x", wbuffer_wreq[i].addr);
		end
		
	end
	

	for (genvar i = 0; i < WMEM_WIDTH; i++) begin
		assign write_commit[i].valid =
		mpipe12[i].valid && mpipe12[i].write && dbus_rresp[0].data_ok && dbus_rresp[1].data_ok;
		assign write_commit[i].data = 'x;
		assign write_commit[i].extra = '0;
		assign write_commit[i].dst = mpipe12[i].dst;
	end
	

	/* Stage 2.R: DCache Request and WriteBuffer (or from Instr I) Fetch */
	for (genvar i = 0; i < RMEM_WIDTH; i++) begin
		assign wbuffer_rreq[i].addr = mpipe12[i].addr;
	end
	
	for (genvar i = 0; i < RMEM_WIDTH; i++) begin
		assign dbus_rreq[i].valid =
		mpipe12[i].valid && mpipe12[i].read;
		assign dbus_rreq[i].addr = mpipe12[i].addr;
		assign dbus_rreq[i].size = mpipe12[i].msize;
		assign dbus_rreq[i].strobe = '0;
		assign dbus_rreq[i].data = 'x;
	end
	
	mpipe23_t [RMEM_WIDTH-1:0] mpipe23, mpipe23_nxt;
	for (genvar i = 0; i < RMEM_WIDTH; i++) begin
		assign mpipe23_nxt[i].valid = mpipe12[i].valid && dbus_rresp[0].data_ok && dbus_rresp[1].data_ok;
		assign mpipe23_nxt[i].addr_off = mpipe12[i].addr[2:0];
		assign mpipe23_nxt[i].dst = mpipe12[i].dst;
		assign mpipe23_nxt[i].msize = mpipe12[i].msize;
		assign mpipe23_nxt[i].wbuffer_rresp = wbuffer_rresp[i];
		assign mpipe23_nxt[i].prev.valid =
		(i == 0 || ~mpipe12[i].valid || ~mpipe12[i].write) ?
		'0 : mpipe12[i].strobe;
		assign mpipe23_nxt[i].prev.data = mpipe12[i].data;
		assign mpipe23_nxt[i].mem_unsigned = mpipe12[i].mem_unsigned;

		always_ff @(posedge clk) begin
			if (reset | 0 /* TODO */) begin
				mpipe23[i].valid <= '0;
			end else begin
				mpipe23[i] <= mpipe23_nxt[i];
			end
		end
		
	end
	
	/* Stage 3.R: DCache Response passing FF, merge prev and writebuffer */
	mpipe34_t [RMEM_WIDTH-1:0] mpipe34, mpipe34_nxt;

	for (genvar i = 0; i < RMEM_WIDTH; i++) begin
		assign mpipe34_nxt[i].valid = mpipe23[i].valid;
		assign mpipe34_nxt[i].addr_off = mpipe12[i].addr[2:0];
		assign mpipe34_nxt[i].dst = mpipe23[i].dst;
		assign mpipe34_nxt[i].msize = mpipe23[i].msize;
		// assign mpipe34_nxt[i].wbuffer_rresp = ;
		assign mpipe34_nxt[i].wbuffer_rresp.valid = 
		mpipe23[i].wbuffer_rresp.valid | mpipe23[i].prev.valid;
		for (genvar j = 0; j < 8; j++) begin
			assign mpipe34_nxt[i].wbuffer_rresp.data[i] =
			mpipe23[i].prev.valid[i] ? 
			mpipe23[i].prev.data[i] : mpipe23[i].wbuffer_rresp.data[i];
		end
		
		assign mpipe34_nxt[i].mem_unsigned = mpipe23[i].mem_unsigned;

		always_ff @(posedge clk) begin
			if (reset | 0 /* TODO */) begin
				mpipe34[i].valid <= '0;
			end else begin
				mpipe34[i] <= mpipe34_nxt[i];
			end
		end
		
	end

	/* Stage 4.R: DCache Response, Merge WriteBuffer and Handle ByteWrite */
	u64 [1:0] rdata;
	u64 [1:0] merged_data;

	for (genvar i = 0; i < RMEM_WIDTH; i++) begin
		for (genvar j = 0; j < 8; j++) begin
			assign merged_data[i][j*8+7:j*8] = 
			mpipe34[i].wbuffer_rresp.valid[j] ?
			mpipe34[i].wbuffer_rresp.data[j] : 
			dbus_rresp[i].data[j*8+7:j*8];
		end
		
		readdata readdata(
			._rd(merged_data[i]),
			.msize(mpipe34[i].msize),
			.addr(mpipe34[i].addr_off),
			.mem_unsigned(mpipe34[i].mem_unsigned),
			.rd(rdata[i])
		);
		assign read_commit[i].valid = mpipe34[i].valid;
		assign read_commit[i].data = rdata[i];
		assign read_commit[i].extra = '0;
		assign read_commit[i].dst = mpipe34[i].dst;
	end
	
endmodule

module batched_fifo
	import common::*;
#(
	parameter QLEN = 32,
	parameter DATA_WIDTH = 128,
	localparam type addr_t = logic[$clog2(QLEN)-1:0],
	localparam type ptr_t = logic[$clog2(QLEN):0],
	localparam type entry_t = logic[DATA_WIDTH-1:0]
) (
	input logic clk, reset,
	input entry_t data_i,
	output entry_t data_o,

	/* Control Singals */
	output u1 empty,
	output u1 full,
	input u1 wen,
	input u1 ren
);
	entry_t fifo [QLEN-1:0];
	ptr_t h, h_nxt, t, t_nxt;

	assign data_o = fifo[addr_t'(h)];

	always_ff @(posedge clk) begin
		if (reset) begin
			h <= '0;
			t <= '0;
		end else begin
			h <= h_nxt;
			t <= t_nxt;
		end
	end

	u1 valid;
	always_ff @(posedge clk) begin
		if (valid) fifo[addr_t'(t)] <= data_i;
	end
	

	assign empty = h == t;
	assign full = h[$bits(ptr_t) - 1] != t[h[$bits(ptr_t) - 1]]
				&& addr_t'(h) == addr_t'(t);

	always_comb begin
		h_nxt = h;
		t_nxt = t;
		valid = '0;
		/* Write */
		if (~full) begin
			if (ren && empty) begin /* Skip fifo */
				
			end else begin
				valid = wen;
				h_nxt = h_nxt + 1;
			end
		end

		/* Read */
		if (ren && ~empty) begin
			t_nxt = t_nxt + 1;
		end
	end
	
	
endmodule

`endif