`ifndef __FORWARD_SV
`define __FORWARD_SV


`include "include/interface.svh"
module forward
    import common::*; 
    import forward_pkg::*;(
    forward_intf.forward self
);
	always_comb begin : forwardAD
		self.forwardAD = NOFORWARD;
		if (self.dataM.instr.ctl.regwrite && 
			self.dataM.writereg == self.instrD.rs1 && 
			self.dataM.writereg != '0) begin
			self.forwardAD = FORWARDM;
		end else if (self.dataW.instr.ctl.regwrite && 
			self.dataW.writereg == self.instrD.rs1 && 
			self.dataW.writereg != '0) begin
			self.forwardAD = FORWARDW;
		end
	end : forwardAD

	always_comb begin : forwardBD
		self.forwardBD = NOFORWARD;
		if (self.dataM.instr.ctl.regwrite && 
			self.dataM.writereg == self.instrD.rs2 && 
			self.dataM.writereg != '0) begin
			self.forwardBD = FORWARDM;
		end else if (self.dataW.instr.ctl.regwrite && 
				self.dataW.writereg == self.instrD.rs2 && 
				self.dataW.writereg != '0) begin
			self.forwardBD = FORWARDW;
		end
	end : forwardBD

	always_comb begin : forwardAE
		self.forwardAE = NOFORWARD;
		if (self.dataM.instr.ctl.regwrite && 
			self.dataM.writereg == self.instrE.rs1 && 
			self.dataM.writereg != '0) begin
			self.forwardAE = FORWARDM;
		end
	end : forwardAE

	always_comb begin : forwardBE
		self.forwardBE = NOFORWARD;
		if (self.dataM.instr.ctl.regwrite && 
			self.dataM.writereg == self.instrE.rs2 && 
			self.dataM.writereg != '0) begin
			self.forwardBE = FORWARDM;
		end
	end : forwardBE
    
endmodule



`endif