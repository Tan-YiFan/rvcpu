`ifndef __BRANCHPREDICT_SV
`define __BRANCHPREDICT_SV

`ifdef VERILATOR
`include "include/interface.svh"
`include "pipeline/fetch/bp/comp_2bit.sv"
`include "pipeline/fetch/bp/jrstack.sv"
`else
`include "interface.svh"
`endif
module branchpredict
	import common::*;(
	input logic clk, reset,
	bp_intf.bp self
);
	u1 [FETCH_WIDTH-1:0] pred_taken_comp;
	u1 [FETCH_WIDTH-1:0] pop_valid, push_valid;
	always_comb begin
		pop_valid = '0;
		push_valid = '0;
		for (int i = 0; i < FETCH_WIDTH; i++) begin
			unique if (self.call[i]) begin
				push_valid[i] = '1;
				break;
			end else if (self.ret[i]) begin
				pop_valid[i] = '1;
				break;
			end else if(pred_taken_comp[i]) begin
				break;
			end
		end
	end
	

	comp_2bit comp_2bit_inst (
		.clk, .reset,
		.pcF(self.pcF[0]),
		.pred_taken(pred_taken_comp),

		.pc_update(self.pc_update),
		.valid(self.valid),
		.taken(self.taken)
	);

	jrstack jrstack_inst (
		.clk, .reset,
		.pc_i(self.pcF),
		.pop_valid(pop_valid),
		.push_valid(push_valid),
		.pc_o(self.pc_ret)
	);
	assign self.pred_taken = pred_taken_comp | self.call | self.ret;

endmodule

`endif
