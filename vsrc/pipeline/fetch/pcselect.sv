`ifndef __PCSELECT_SV
`define __PCSELECT_SV

`ifdef VERILATOR
`include "include/interface.svh"
`else
`include "interface.svh"
`endif
module pcselect
	import common::*;
	(
	pcselect_intf.pcselect self,
	freg_intf.pcselect freg
);
	always_comb begin
		freg.pc_nxt = '0;
		// pc + 4, 8, ...
		for (int i = 0; i < FETCH_WIDTH; i++) begin
			if (self.validF[i]) begin
				freg.pc_nxt = self.pcF[i];
			end
		end
		// branches
		for (int i = 0; i < FETCH_WIDTH; i++) begin
			if (self.branch_takenF[i]) begin
				freg.pc_nxt = self.pcbranchF[i];
				break;
			end
		end
		
	end
	

endmodule



`endif