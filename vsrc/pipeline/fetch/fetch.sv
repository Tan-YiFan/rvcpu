`ifndef __FETCH_SV
`define __FETCH_SV


`ifdef VERILATOR
`include "include/interface.svh"
`else
`include "interface.svh"
`endif
module fetch 
	import common::*;
	import fetch_pkg::*;
	(
	pcselect_intf.fetch pcselect,
	freg_intf.fetch freg,
	dreg_intf.fetch dreg,
	output u64 pc,
	input ibus_resp_t iresp
);
	fetch_data_t dataF;
	assign pc = freg.pc;

	for (genvar i = 0; i < FETCH_WIDTH; i++) begin
		assign dataF.instr[i].valid = iresp.data[i].valid;
		assign dataF.instr[i].raw_instr = iresp.data[i].raw_instr;
		assign dataF.instr[i].pc = pc + i * 4;
		assign dataF.instr[i].jump = 1'b0;
		assign dataF.instr[i].pcjump = '0;
	end

	for (genvar i = 0; i < FETCH_WIDTH; i++) begin
		assign pcselect.validF[i] = dataF.instr[i].valid;
		assign pcselect.pcF[i] = dataF.instr[i].pc + 4;
		assign pcselect.branch_takenF[i] = '0;
		assign pcselect.pcbranchF[i] = '0;
	end
	

	assign dreg.dataF_nxt = dataF;
endmodule


`endif