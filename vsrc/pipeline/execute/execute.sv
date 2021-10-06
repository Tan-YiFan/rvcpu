`ifndef __EXECUTE_SV
`define __EXECUTE_SV

`ifdef VERILATOR
`include "include/interface.svh"
`include "pipeline/execute/alu.sv"
`include "pipeline/execute/multicycle.sv"
`else
`include "interface.svh"
`endif
module execute
	import common::*;
	import decode_pkg::*;
	import execute_pkg::*;
	import source_pkg::*;(
	input logic clk, reset,
	ereg_intf.execute ereg,
	creg_intf.execute creg
	// forward_intf.execute forward
);
	source_data_t dataS;
	execute_data_t dataE;

	word_t [3:0] alu_result;
	for (genvar i = 0; i < 4; i++) begin
		alu alu_inst (
			.a(dataS.alu_source[i].d1),
			.b(dataS.alu_source[i].d2),
			.c(alu_result[i]),
			.alufunc(dataS.alu_source[i].ctl.alufunc)
		);
	end

	for (genvar i = 0; i < 4; i++) begin
		assign dataE.
	end
	

	assign dataS = ereg.dataS;
	assign creg.dataE_nxt = dataE;
endmodule


`endif
