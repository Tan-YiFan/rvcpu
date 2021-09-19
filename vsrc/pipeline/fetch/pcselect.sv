`ifndef __PCSELECT_SV
`define __PCSELECT_SV


`include "include/interface.svh"

module pcselect
	import common::*;
	(
	pcselect_intf.pcselect self,
	freg_intf.pcselect freg
);
	assign freg.pc_nxt = self.branch_taken ? self.pcbranch :
			     self.jr 	       ? self.pcjr:
			     self.jump         ? self.pcjump : self.pcplus4F;

endmodule



`endif