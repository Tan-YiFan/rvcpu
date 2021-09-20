`ifndef __HAZARD_SV
`define __HAZARD_SV



`include "include/interface.svh"
module hazard 
    import common::*;(
    hazard_intf.hazard self,
    input u1 i_data_ok, d_data_ok
);
	logic regwriteE, memreadM, memreadE;
	creg_addr_t writeregE, writeregM;
	assign regwriteE = self.dataE.instr.ctl.regwrite;
	assign memreadM = self.dataM.instr.ctl.memread;
	assign memreadE = self.dataE.instr.ctl.memread;
	assign writeregE = self.dataE.writereg;
	assign writeregM = self.dataM.writereg;
	
	logic lwstall;
	assign lwstall = ((self.dataD.instr.rs1 == writeregE || self.dataD.instr.rs2 == writeregE) && memreadE && writeregE != '0) || 
			((self.dataD.instr.rs1 == writeregM || self.dataD.instr.rs2 == writeregM) && memreadM && writeregM != '0);

	logic branchstall;
	assign branchstall = (self.dataD.instr.ctl.branch | self.dataD.instr.ctl.jump) &&
				((regwriteE && writeregE == self.dataD.instr.rs1 && writeregE != '0) ||
				(memreadM && writeregM == self.dataD.instr.rs1 && writeregM != '0) || ((
					(regwriteE && writeregE == self.dataD.instr.rs2 && writeregE != '0) ||
					(memreadM && writeregM == self.dataD.instr.rs2 && writeregM != '0)
				)
				));


	wire flush_ex = 1'b0;
	assign self.stallF = ~i_data_ok | ~d_data_ok | lwstall | branchstall | ~self.mult_ok;
	assign self.stallD = ~i_data_ok | ~d_data_ok | lwstall | branchstall | ~self.mult_ok;
	assign self.stallE = (~d_data_ok) | ~self.mult_ok;
	assign self.stallM = ~d_data_ok;

	assign self.flushD = flush_ex | (self.branch_taken & ~self.stallD);
	assign self.flushE = ((lwstall | branchstall | ~i_data_ok) & self.mult_ok & d_data_ok);
	assign self.flushM = (~self.mult_ok & d_data_ok) | (flush_ex & i_data_ok);
	assign self.flushW = ~d_data_ok;
endmodule


`endif