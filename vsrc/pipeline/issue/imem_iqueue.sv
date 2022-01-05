`ifndef __IMEM_IQUEUE_SV
`define __IMEM_IQUEUE_SV

`ifdef VERILATOR

`else

`endif

/* FIFO 2r4w */

/* Inorder memory */
module imem_iqueue
	import common::*;
	import issue_pkg::*;
	import decode_pkg::*;#(
	parameter QLEN = 8,
	parameter WNUM = 4,
	parameter RNUM = 2,

	localparam type iq_addr_t = logic[$clog2(QLEN)-1:0],
	localparam type iq_ptr_t = logic[$clog2(QLEN):0],
	localparam type addr_t = iq_addr_t,
	localparam type ptr_t = iq_ptr_t
)(
	input logic clk, reset, wen, stall,
	input write_req_t [FETCH_WIDTH-1:0] write,
	input wake_req_t [WAKE_NUM-1:0] wake,
	input wake_req_t [COMMIT_WIDTH-1:0] retire,
	// input u1[WAKE_NUM-1:0] wake,
	// input word_t wake_data[WAKE_NUM-1:0],
	output read_resp_t [1:0] read,

	output logic full
);
	logic v[QLEN-1:0], v_nxt[QLEN-1:0], v1[QLEN-1:0], v1_nxt[QLEN-1:0], v2[QLEN-1:0], v2_nxt[QLEN-1:0];
	u1 f1[QLEN-1:0], f1_nxt[QLEN-1:0], f2[QLEN-1:0], f2_nxt[QLEN-1:0];
	preg_addr_t s1[QLEN-1:0], s2[QLEN-1:0], s1_nxt[QLEN-1:0], s2_nxt[QLEN-1:0];
	/* Implemented in RAM */
	localparam type packed_t = struct packed {
		rob_ptr_t dst;
		control_t ctl;
		word_t imm;
		pc_t pc;
		creg_addr_t c1, c2;
	};
	function u1 iq_valid(iq_addr_t i);
		return v[i] && v1[i] && v2[i];
	endfunction

	packed_t pdata[WNUM-1:0][QLEN/WNUM-1:0];

	iq_ptr_t h[RNUM-1:0], t[WNUM-1:0], h_nxt, t_nxt;
	localparam type bank_t = logic [$clog2(WNUM)-1:0];
	localparam type bank_offset_t = logic[$clog2(QLEN)-1-$clog2(WNUM):0];

	function bank_t bank(addr_t p);
		return p[$clog2(WNUM)-1:0];
	endfunction
	function bank_offset_t bank_offset(addr_t p);
		return p[$clog2(QLEN)-1:$clog2(WNUM)];
	endfunction

	always_ff @(posedge clk) begin
		if (reset) begin
			for (int i = 0; i < RNUM; i++) begin
				h[i] <= i;
			end
			for (int i = 0; i < WNUM; i++) begin
				t[i] <= i;
			end
			
		end else begin
			for (int i = 0; i < RNUM; i++) begin
				h[i] <= i + h_nxt;
			end
			for (int i = 0; i < WNUM; i++) begin
				t[i] <= i + t_nxt;
			end
		end
	end

	packed_t preads[WNUM-1:0][RNUM-1:0];
	packed_t pread[RNUM-1:0];
	u2 read_num;

	for (genvar i = 0; i < RNUM; i++) begin
		for (genvar j = 0; j < WNUM; j++) begin
			assign preads[j][i] = pdata[j][bank_offset(h[i])];
		end
		assign pread[i] = pdata[bank(h[i])][bank_offset(h[i])];
		assign read[i].entry.valid = /* v[h[i]] */iq_valid(h[i]) && ~stall && i < read_num;
		assign read[i].entry.src1.valid = v1[h[i]];
		assign read[i].entry.src1.id = preads[bank(h[i])][i].c1;
		assign read[i].entry.src1.pid = s1[h[i]];
		assign read[i].entry.src1.forward_en = f1[h[i]];
		assign read[i].entry.src2.valid = v2[h[i]];
		assign read[i].entry.src2.id = preads[bank(h[i])][i].c2;
		assign read[i].entry.src2.pid = s2[h[i]];
		assign read[i].entry.src2.forward_en = f2[h[i]];
		assign read[i].entry.dst = preads[bank(h[i])][i].dst;
		assign read[i].entry.ctl = preads[bank(h[i])][i].ctl;
		assign read[i].entry.imm = preads[bank(h[i])][i].imm;
		assign read[i].entry.pc = preads[bank(h[i])][i].pc;
		always_ff @(posedge clk) begin
			// if (read[i].entry.valid) $display("%x %x %x %x", read[i].entry.pc, h[i], i, t[i]);
		end
	end
	// always_ff @(posedge clk) begin
	// 	if (read[0].entry.valid) $display("%x", pdata[0][0].pc);
	// end
	
	
	
	
	// for (genvar j = 0; j < RNUM; j++) begin
	// 	for (genvar i = 0; i < WNUM; i++) begin
	// 		assign preads[j][i] = pdata[i][bank_offset(h[j])];
	// 	end
	// 	// assign pread[j] = preads[bank(h[j])];
	// 	assign read[j].entry.valid = v[h[j]] && ~stall;
	// 	assign read[j].entry.src1 = s1[h[j]];
	// 	assign read[j].entry.src2 = s2[h[j]];
	// 	assign read[j].entry.dst = preads[j][bank(h[j])].dst;
	// 	assign read[j].entry.ctl = preads[j][bank(h[j])].ctl;
	// 	assign read[j].entry.imm = preads[j][bank(h[j])].imm;
	// 	assign read[j].entry.pc = preads[j][bank(h[j])].pc;
	// 	always_ff @(posedge clk) begin
	// 		if (read[j].entry.valid) $display("%x", read[j].entry.pc);
	// 	end
		
	// end
	
	
	always_comb begin
		read_num = '0;
		if (~stall) begin
			if (h[0] != t[0] && iq_valid(h[0])) begin
				read_num = 1;
				if (h[1] != t[0] && iq_valid(h[1])) read_num = 2;
			end
		end
	end
	
	
	// assign h_nxt = h[0] + read_num;
	logic [$clog2(WNUM):0] wnum;
	write_req_t [WNUM-1:0] wdata;
	logic [WNUM-1:0] wvalid;
	always_comb begin
		full = '0;
		for (int i = 0; i < 4; i++) begin
			if (addr_t'(t[i]) == addr_t'(h[0]) && t[i][$bits(addr_t)] != h[0][$bits(addr_t)]) full = '1;
		end
		
	end
	always_ff @(posedge clk) begin
		// if (|wvalid) $display("%x %x %x %x %x", t[0], t_nxt, pwdata[bank(t[0])].pc, wnum, wvalid);
	end
	always_ff @(posedge clk) begin
		// if (h[0] != h_nxt) $display("%x %x %x %x", h[0], h_nxt, read[0].entry.valid, read_num); 
	end
	
	always_comb begin
		wnum = '0;
		wdata = 'x;
		wvalid = '0;
		if (wen) begin
			for (int i = 0; i < WNUM; i++) begin
				if (write[i].valid) begin
					wdata[bank(t[wnum])] = write[i];
					wvalid[bank(t[wnum])] = 1'b1;
					// $display("%x", wdata[bank(t[wnum])].entry.pc);
					wnum++;
					
				end
			end
		end 
	end
	assign t_nxt = ~wen ? t[0] : (t[0] + wnum);

	packed_t [WNUM-1:0] pwdata;
	for (genvar i = 0; i < WNUM; i++) begin
		assign pwdata[i].dst = wdata[i].entry.dst;
		assign pwdata[i].ctl = wdata[i].entry.ctl;
		assign pwdata[i].imm = wdata[i].entry.imm;
		assign pwdata[i].pc = wdata[i].entry.pc;
		assign pwdata[i].c1 = wdata[i].entry.src1.id;
		assign pwdata[i].c2 = wdata[i].entry.src1.id;
		// always_ff @(posedge clk) begin
		// 	if (wvalid[i] && wen) $display("%x", pwdata[i].pc);
		// end
		
	end
	
	for (genvar i = 0; i < WNUM; i++) begin
		always_ff @(posedge clk) begin
			if (wvalid[addr_t'(i-addr_t'(t[0]))] && wen) begin
				pdata[i][bank_offset(t[addr_t'(i-addr_t'(t[0]))])] <= pwdata[addr_t'(i-addr_t'(t[0]))];
			end
		end
	end
	for (genvar i = 0; i < QLEN; i++) begin
		always_ff @(posedge clk) begin
			if (reset) begin
				v[i] <= '0;
			end else begin
				v[i] <= v_nxt[i];
				v1[i] <= v1_nxt[i];
				v2[i] <= v2_nxt[i];
				f1[i] <= f1_nxt[i];
				f2[i] <= f2_nxt[i];
				s1[i] <= s1_nxt[i];
				s2[i] <= s2_nxt[i];
			end
		end	
	end

	always_comb begin
		// v_nxt = v;
		// v1_nxt = v1;
		// v2_nxt = v2;
		h_nxt = h[0];
		for (int i = 0; i < QLEN; i++) begin
			v_nxt[i] = v[i];
			v1_nxt[i] = v1[i];
			v2_nxt[i] = v2[i];
			f1_nxt[i] = f1[i];
			f2_nxt[i] = f2[i];
			s1_nxt[i] = s1[i];
			s2_nxt[i] = s2[i];
		end
		
		// write
		if (wen) begin
			for (int i = 0; i < FETCH_WIDTH; i++) begin
				if (i == wnum) break;
				v_nxt[t[i]] = 1'b1;
				v1_nxt[t[i]] = wdata[i].entry.src1.valid;
				v2_nxt[t[i]] = wdata[i].entry.src2.valid;
				f1_nxt[t[i]] = wdata[i].entry.src1.forward_en;
				f2_nxt[t[i]] = wdata[i].entry.src2.forward_en;
				s1_nxt[t[i]] = wdata[i].entry.src1.pid;
				s2_nxt[t[i]] = wdata[i].entry.src2.pid;
			end
		end
		// wake
		for (int i = 0; i < QLEN; i++) begin
			for (int j = 0; j < WAKE_NUM; j++) begin
				if (wake[j].valid && s1[i] == wake[j].id) begin
					v1_nxt[i] = 1'b1;
				end
				if (wake[j].valid && s2[i] == wake[j].id) begin
					v2_nxt[i] = 1'b1;
				end
			end
			for (int j = 0; j < COMMIT_WIDTH; j++) begin
				if (retire[j].valid && s1[i] == retire[j].id) begin
					v1_nxt[i] = 1'b1;
					f1_nxt[i] = 1'b0;
				end
				if (retire[j].valid && s2[i] == retire[j].id) begin
					v2_nxt[i] = 1'b1;
					f2_nxt[i] = 1'b0;
				end
			end
		end
		// read
		if (~stall) begin
			for (int i = 0; i < 2; i++) begin
				if (/* i == read_num */~read[i].entry.valid) break;
				v_nxt[h[i]] = 1'b0;
				h_nxt = h[1] + i;
			end
			
			// v_nxt[chosen] = 1'b0;
		end
	end

	
endmodule


`endif
