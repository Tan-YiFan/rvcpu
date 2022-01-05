`ifndef __COMP_2BIT_SV
`define __COMP_2BIT_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "pipeline/fetch/bp/local_2bit.sv"
`else

`endif

module comp_2bit
	import common::*;
	#(
		parameter FETCH_WIDTH = 4
	)(
	input logic clk, reset,

	/* Read: FETCH_WIDTH items */
	input u64 pcF,
	output logic [FETCH_WIDTH-1:0] pred_taken,

	/* Update: 1 item */
	input u64 pc_update,
	input u1 valid,
	input u1 taken
);

	local_2bit local_2bit(.*);
endmodule

`endif
