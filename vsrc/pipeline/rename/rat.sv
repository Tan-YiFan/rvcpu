`ifndef __RAT_SV
`define __RAT_SV

`ifdef VERILATOR
`include "include/interface.svh"
`else
`include "interface.svh"
`endif

module rat
	import common::*;
	import rename_pkg::*;(
	input logic clk, reset,
	rename_intf.rat rename,
    retire_intf.rat retire
);
	u1 [CREG_NUM-1:0] v;
	preg_addr_t t[CREG_NUM-1:0];
	always_ff @(posedge clk) begin
		if (reset) begin
			v <= '0;
		end else begin
			// retire
			for (int i = 0; i < COMMIT_WIDTH; i++) begin
				for (int j = 0; j < CREG_NUM; j++) begin
					if (retire.retire[i].valid && 
						retire.retire[i].dst == j && 
						retire.retire[i].preg == t[j]) begin
						v[j] <= 1'b0;
					end
				end
			end
			// rename
			for (int i = 0; i < FETCH_WIDTH; i++) begin
				for (int j = 0; j < CREG_NUM; j++) begin
					if (rename.instr[i].valid && rename.instr[i].dst != 0 && rename.instr[i].dst == j) begin
						v[j] <= 1'b1;
					end
				end
			end
		end
	end
	
	always_ff @(posedge clk) begin
		// rename
		for (int i = 0; i < FETCH_WIDTH; i++) begin
			if (rename.instr[i].valid && rename.instr[i].dst != 0) begin
				t[rename.instr[i].dst] <= rename.psrc[i];
			end
		end
	end
	
	// read
	for (genvar i = 0; i < FETCH_WIDTH; i++) begin
		assign rename.info[i].psrc1.valid = v[rename.instr[i].src1];
		assign rename.info[i].psrc1.id = t[rename.instr[i].src1];
		assign rename.info[i].psrc2.valid = v[rename.instr[i].src2];
		assign rename.info[i].psrc2.id = t[rename.instr[i].src2];
	end
	
	
endmodule


`endif
