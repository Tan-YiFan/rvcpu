// `ifndef __REGFILE_SV
// `define __REGFILE_SV
// `ifdef VERILATOR
// `include "include/interface.svh"
// `else
// `include "interface.svh"
// `endif
// module regfile 
// 	import common::*;
// 	#(
// 	parameter READ_PORTS = AREG_READ_PORTS,
// 	parameter WRITE_PORTS = AREG_WRITE_PORTS
// ) (
// 	input logic clk, reset,
// 	// regfile_intf.regfile self
// 	source_intf.regfile source,
// 	retire_intf.regfile retire
// );
// 	u64 [31:0]regs, regs_nxt;

// 	for (genvar i = 0; i < READ_PORTS; i++) begin
// 		assign source.arf1[i] = regs[source.src1[i]];
// 		assign source.arf2[i] = regs[source.src2[i]];
// 	end

// 	initial begin
// 		for (int i = 0; i < 32; i++) begin
// 			regs[i] = 0;
// 		end
// 	end
// 	// always_ff @(posedge clk) begin
// 	// 	for (int j = 0; j < WRITE_PORTS; j++) begin
// 	// 		if (self.valid[j]) begin
// 	// 			regs[self.wa[j]] = self.wd[j];
// 	// 		end
// 	// 	end
// 	// end
// 	always_ff @(posedge clk) begin
// 		regs <= regs_nxt;
// 	end
	
	
// 	for (genvar i = 1; i < 32; i++) begin
// 		always_comb begin
// 			regs_nxt[i] = regs[i];
// 			for (int j = 0; j < WRITE_PORTS; j++) begin
// 				if (retire.retire[j].valid && i == retire.retire[j].dst && retire.retire[j].ctl.regwrite) begin
// 					regs_nxt[i] = retire.retire[j].data;
// 				end
// 			end
// 		end
// 	end
		
	

// endmodule

// module preg 
// 	import common::*;
// 	#(
// 	parameter READ_PORTS = 20,
// 	parameter WRITE_PORTS = 1
// ) (
// 	input logic clk, reset,
// 	input preg_addr_t [READ_PORTS-1:0] ra1, ra2,
// 	input preg_addr_t [WRITE_PORTS-1:0] wa,
// 	input logic[WRITE_PORTS-1:0] valid,
// 	input u64[WRITE_PORTS-1:0] wd,
// 	output u64[READ_PORTS-1:0] rd1, rd2
// );
// 	// u64 regs[PREG_NUM-1:0];

// 	// for (genvar i = 0; i < READ_PORTS; i++) begin
// 	// 	assign rd1[i] = regs[ra1[i]];
// 	// 	assign rd2[i] = regs[ra2[i]];
// 	// end

// 	// initial begin
// 	// 	for (int i = 0; i < PREG_NUM; i++) begin
// 	// 		regs[i] = 0;
// 	// 	end
// 	// end
// 	// always_ff @(posedge clk) begin
// 	// 	for (int j = 0; j < WRITE_PORTS; j++) begin
// 	// 		if (valid[j]) begin
// 	// 			regs[wa[j]] = wd[j];
// 	// 		end
// 	// 	end
// 	// end
// 	for (genvar i = 0; i < READ_PORTS; i++) begin
// 		RAM_SimpleDualPort #(
// 			.ADDR_WIDTH(6),
// 			.DATA_WIDTH(64),
// 			.BYTE_WIDTH(64),
// 			.MEM_TYPE(0),
// 			.READ_LATENCY(0)
// 		) ram1 (
// 			.clk, .en(1'b1),
// 			.raddr(ra1[i]),
// 			.waddr(wa[0]),
// 			.strobe(valid[0]),
// 			.wdata(wd[0]),
// 			.rdata(rd1[i])
// 		);
// 		RAM_SimpleDualPort #(
// 			.ADDR_WIDTH(6),
// 			.DATA_WIDTH(64),
// 			.BYTE_WIDTH(64),
// 			.MEM_TYPE(0),
// 			.READ_LATENCY(0)
// 		) ram2 (
// 			.clk, .en(1'b1),
// 			.raddr(ra2[i]),
// 			.waddr(wa[0]),
// 			.strobe(valid[0]),
// 			.wdata(wd[0]),
// 			.rdata(rd2[i])
// 		);
// 	end
	

// endmodule

// `endif

module preg #(
	parameter type T = logic[63:0],
	parameter WNUM = 4,
	parameter RNUM = 16,
	parameter QLEN = 64,
	parameter MEM_TYPE = 1,
	localparam type addr_t = logic[$clog2(QLEN)-1:0],
	localparam type S = logic [500:0]
) (
	input logic clk, reset,
	input S in,
	output S out
);
if (MEM_TYPE == 0) begin
	T [QLEN-1:0] data;

	T [RNUM-1:0] rdata;
	addr_t [RNUM-1:0] ra;

	T [WNUM-1:0] wdata;
	logic [WNUM-1:0] wvalid;
	addr_t [WNUM-1:0] wa;

	for (genvar i = 0; i < RNUM; i++) begin
		assign rdata[i] = data[ra[i]];
	end
	
	always_ff @(posedge clk) begin
		for (int i = 0; i < WNUM; i++) begin
			if (wvalid[i]) data[wa[i]] <= wdata[i];
		end
		
	end
	
	always_ff @(posedge clk) begin
		{wdata, ra, wvalid, wa} <= in;
		out <= {rdata};
	end
end else begin

	T data[WNUM-1:0][QLEN/WNUM-1:0];

	T [RNUM-1:0] rdata;
	addr_t [RNUM-1:0] ra;

	T [WNUM-1:0] wdata;
	logic [WNUM-1:0] wvalid;
	addr_t [WNUM-1:0] wa;

	localparam type bank_t = logic [$clog2(WNUM)-1:0];
	localparam type bank_offset_t = logic[$clog2(QLEN)-1-$clog2(WNUM):0];
	function bank_t bank(addr_t p);
		return p[$clog2(WNUM)-1:0];
	endfunction
	function bank_offset_t bank_offset(addr_t p);
		return p[$clog2(QLEN)-1:$clog2(WNUM)];
	endfunction
	
	bank_offset_t ra2[WNUM-1:0][RNUM-1:0];
	T r2[WNUM-1:0][RNUM-1:0];

	always_comb begin
		for (int i = 0; i < WNUM; i++) begin
			for (int j = 0; j < RNUM; j++) begin
				ra2[i][j] = 'x;
			end
		end
		for (int i = 0; i < WNUM; i++) begin
			ra2[bank(ra[i])][i] = bank_offset(ra[i]);
		end
	end
	
	for (genvar i = 0; i < WNUM; i++) begin
		for (genvar j = 0; j < RNUM; j++) begin
			RAM_SimpleDualPort #(
				.ADDR_WIDTH($clog2(QLEN/WNUM)),
				.DATA_WIDTH($bits(T)),
				.BYTE_WIDTH($bits(T)),
				.MEM_TYPE(0),
				.READ_LATENCY(0)
			) wb_buffer (
				.clk, .en(1'b1),
				.raddr(ra2[i][j]),
				.waddr(bank_offset(wa[i])),
				.strobe(wvalid[i]),
				.wdata(wdata[i]),
				.rdata(r2[i][j])
			);
		end
		
	end
	for (genvar i = 0; i < RNUM; i++) begin
		assign rdata[i] = r2[bank(ra[i])][i];
	end
	
	
	always_ff @(posedge clk) begin
		{wdata, ra, wvalid, wa} <= in;
		out <= {rdata};
	end
end	
endmodule