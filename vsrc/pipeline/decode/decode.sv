`ifndef __DECODE_SV
`define __DECODE_SV

`ifdef VERILATOR
`include "include/interface.svh"
`include "pipeline/decode/decoder.sv"
`include "pipeline/execute/bru.sv"
`else
`include "interface.svh"
`endif

module decode 
	import common::*;
	import decode_pkg::*;
	import fetch_pkg::*;(
	input logic clk, reset,
	dreg_intf.decode dreg,
	rreg_intf.decode rreg
);
	decoded_instr_t instr[FETCH_WIDTH-1:0];

	for (genvar i = 0; i < FETCH_WIDTH; i++) begin
		decoder decoder_inst (
			.raw_instr(dreg.dataF.instr[i].raw_instr),
			.instr(instr[i])
		);
	end
	decode_data_t dataD;
	for (genvar i = 0; i < FETCH_WIDTH; i++) begin
		assign dataD.instr[i] = {
			dreg.dataF.instr[i].valid,
			instr[i],
			dreg.dataF.instr[i].pc,
			dreg.dataF.instr[i].jump,
			dreg.dataF.instr[i].pcjump
		};
	end
	assign rreg.dataD_nxt = dataD;
	
endmodule


`endif