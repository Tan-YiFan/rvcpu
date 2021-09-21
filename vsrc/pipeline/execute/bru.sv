`ifndef __BRU_SV
`define __BRU_SV


`ifdef VERILATOR
`include "include/interface.svh"
`else
`include "interface.svh"
`endif

module bru 
	import common::*;
	import decode_pkg::*;(
	input branch_t branch_type,
	input u64 a, b,
	output u1 branch_taken
);
	always_comb begin
		branch_taken = 1'b0;
		unique case(branch_type)
			B_BEQ: begin
				branch_taken = a == b;
			end
			B_BNE: begin
				branch_taken = a != b;
			end
			B_BLT: begin
				branch_taken = $signed(a) < $signed(b);
			end
			B_BGE: begin
				branch_taken = $signed(a) >= $signed(b);
			end
			B_BLTU: begin
				branch_taken = a < b;
			end
			B_BGEU: begin
				branch_taken = a >= b;
			end
			default: begin
				
			end
		endcase
	end
	
endmodule



`endif