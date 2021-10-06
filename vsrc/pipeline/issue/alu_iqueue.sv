`ifndef __ALU_IQUEUE_SV
`define __ALU_IQUEUE_SV

`ifdef VERILATOR

`endif

module alu_iqueue
	import common::*;
	import issue_pkg::*;
	import decode_pkg::*;#(
	parameter QLEN = 8,

	localparam type iq_addr_t = logic[$clog2(QLEN)-1:0]
)(
	input logic clk, reset, wen, stall,
	input write_req_t write,
	input wake_req_t [ALU_WAKE_NUM-1:0] wake,
	input wake_req_t [COMMIT_WIDTH-1:0] retire,
	// input u1[WAKE_NUM-1:0] wake,
	// input word_t wake_data[WAKE_NUM-1:0],
	output read_resp_t read,

	output logic full
);
	iq_addr_t chosen;

	logic v[QLEN-1:0], v_nxt[QLEN-1:0], v1[QLEN-1:0], v1_nxt[QLEN-1:0], v2[QLEN-1:0], v2_nxt[QLEN-1:0];
	rob_ptr_t dst[QLEN-1:0];
	control_t ctl[QLEN-1:0];
    word_t imm[QLEN-1:0];
	pc_t pc[QLEN-1:0];
	preg_addr_t s1[QLEN-1:0];
	preg_addr_t s2[QLEN-1:0];
	creg_addr_t c1[QLEN-1:0];
	creg_addr_t c2[QLEN-1:0];
	u1 f1[QLEN-1:0], f1_nxt[QLEN-1:0];
	u1 f2[QLEN-1:0], f2_nxt[QLEN-1:0];
	// word_t d1[QLEN-1:0], d1_nxt[QLEN-1:0], d2[QLEN-1:0], d2_nxt[QLEN-1:0];
	function u1 iq_valid(iq_addr_t i);
		return v[i] && v1[i] && v2[i];
	endfunction
	
	
	iq_addr_t fl;
	logic wnum, free;
	assign wnum = write.valid;
	always_comb begin
		free = '0;
		fl = '0;
		for (int i = 0; i < QLEN; i++) begin
			if (~v[i]) begin
				fl = i;
				free = 1'b1;
				break;
			end
		end
	end
	assign full = free < wnum;

	typedef struct packed {
		u1 valid;
		iq_addr_t id;
		rob_ptr_t dst;
	} sel_meta_t;
	sel_meta_t [QLEN-1:0]sel[$clog2(QLEN):0]/* verilator split_var */;
	for (genvar i = 0; i < QLEN; i++) begin
		assign sel[0][i].valid = iq_valid(i);
		assign sel[0][i].id = i;
		assign sel[0][i].dst = dst[i];
	end
	function u1 is_older(sel_meta_t i, j);
		// return ~i.valid ? 1'b0 : (~j.valid ? 1'b1 : (
		// 	(i.dst[$clog2(PREG_NUM)] == j.dst[$clog2(PREG_NUM)]) ^ 
		// 	(i.dst[$clog2(PREG_NUM)-1:0] > j.dst[$clog2(PREG_NUM)-1:0])
		// ));
		return i.valid & j.valid ? (
			(i.dst[$clog2(PREG_NUM)] == j.dst[$clog2(PREG_NUM)]) ^ 
			(i.dst[$clog2(PREG_NUM)-1:0] > j.dst[$clog2(PREG_NUM)-1:0])
		) : i.valid;
	endfunction
	for (genvar i = 0; i < $clog2(QLEN); i++) begin
		for (genvar j = 0; j < QLEN >> i; j += 2) begin
			assign sel[i + 1][j >> 1] = is_older(sel[i][j], sel[i][j+1]) ? sel[i][j] : sel[i][j+1];
		end
	end
	assign chosen = sel[$clog2(QLEN)][0].id;
	
	// always_comb begin
	// 	chosen = '0;
	// 	for (int i = 0; i < QLEN; i++) begin
	// 		if (iq_valid(i)) begin
	// 			chosen = i;
	// 			break;
	// 		end
	// 	end
	// end

	assign read.entry = {
		iq_valid(chosen),
		1'b1,
		c1[chosen],
		s1[chosen],
		// d1[chosen],
		f1[chosen],
		1'b1,
		c2[chosen],
		s2[chosen],
		// d2[chosen],
		f2[chosen],
		dst[chosen],
		ctl[chosen],
		imm[chosen],
		pc[chosen]
	};
	always_ff @(posedge clk) begin
		if (wen) begin
			if (write.valid) begin
				dst[fl] <= write.entry.dst;
				ctl[fl] <= write.entry.ctl;
				imm[fl] <= write.entry.imm;
				pc[fl] <= write.entry.pc;
				s1[fl] <= write.entry.src1.pid;
				s2[fl] <= write.entry.src2.pid;
				c1[fl] <= write.entry.src1.id;
				c2[fl] <= write.entry.src2.id;
				// f1[fl] <= write.entry.src1.forward_en;
				// f2[fl] <= write.entry.src2.forward_en;
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
				// d1[i] <= d1_nxt[i];
				// d2[i] <= d2_nxt[i];
			end
		end
		
	end
	
	// always_ff @(posedge clk) begin
	// 	if (~reset) begin
	// 		v <= '0;
	// 	end else begin
	// 		v <= v_nxt;
	// 		v1 <= v1_nxt;
	// 		v2 <= v2_nxt;
	// 	end
	// end
	
	always_comb begin
		// v_nxt = v;
		// v1_nxt = v1;
		// v2_nxt = v2;
		for (int i = 0; i < QLEN; i++) begin
			v_nxt[i] = v[i];
			v1_nxt[i] = v1[i];
			v2_nxt[i] = v2[i];
			f1_nxt[i] = f1[i];
			f2_nxt[i] = f2[i];
			// d1_nxt[i] = d1[i];
			// d2_nxt[i] = d2[i];
		end
		
		// write
		if (wen) begin
			if (write.valid) begin
				// for (int j = 0; j < QLEN; j++) begin
				// 	if (j == fl) begin
				// 		v_nxt[j] = 1'b1;
				// 		v1_nxt[j] = write.entry.src1.valid;
				// 		v2_nxt[j] = write.entry.src2.valid;
				// 	end
				// end
				v_nxt[fl] = 1'b1;
				v1_nxt[fl] = write.entry.src1.valid;
				v2_nxt[fl] = write.entry.src2.valid;
				f1_nxt[fl] = write.entry.src1.forward_en;
				f2_nxt[fl] = write.entry.src2.forward_en;
				// d1_nxt[fl] = write.entry.src1.data;
				// d2_nxt[fl] = write.entry.src2.data;
			end
		end
		// wake
		for (int i = 0; i < QLEN; i++) begin
			for (int j = 0; j < ALU_WAKE_NUM; j++) begin
				if (wake[j].valid && s1[i] == wake[j].id) begin
					v1_nxt[i] = 1'b1;
					// d1_nxt[i] = wake_data[j];
				end
				if (wake[j].valid && s2[i] == wake[j].id) begin
					v2_nxt[i] = 1'b1;
					// d2_nxt[i] = wake_data[j];
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
			
			// if (wake[s1[i]]) begin
			// 	v1_nxt[i] = 1'b1;
			// 	d1_nxt[i] = wake_data[s1[i]];
			// end
			// if (wake[s2[i]]) begin
			// 	v2_nxt[i] = 1'b1;
			// 	d2_nxt[i] = wake_data[s2[i]];
			// end
		end
		
		// read
		if (~stall & iq_valid(chosen)) begin
			// for (int i = 0; i < QLEN; i++) begin
			// 	if (i == chosen) begin
			// 		v_nxt[i] = 1'b0;
			// 	end
			// end
			v_nxt[chosen] = 1'b0;
		end
	end
	always_ff @(posedge clk) begin
		// $display("%x", v[0]);
	end
	
endmodule

`endif
