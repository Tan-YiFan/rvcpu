`ifndef __FETCH_SV
`define __FETCH_SV



`include "include/interface.svh"

module fetch 
	import common::*;
	import fetch_pkg::*;
	(
	pcselect_intf.fetch pcselect,
	freg_intf.fetch freg,
	dreg_intf.fetch dreg,
	output u64 pc,
	input u32 raw_instr
);
	fetch_data_t dataF;
	assign pc = freg.pc;

	assign dataF.pc = pc;
	assign dataF.raw_instr = raw_instr;
	assign pcselect.pcplus4F = pc + 64'd4;
	assign dreg.dataF_nxt = dataF;
endmodule


`endif