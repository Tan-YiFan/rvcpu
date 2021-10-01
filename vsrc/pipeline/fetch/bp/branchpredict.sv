`ifndef __BRANCHPREDICT_SV
`define __BRANCHPREDICT_SV

`ifdef VERILATOR
`include "include/interface.svh"
`else
`include "interface.svh"
`endif

module branchpredict #(
	
)(
	input logic clk, reset,
	q
);
	two_bit #(

	) two_bit_inst (

	);

	jrstack #(

	) jrstack_inst (

	);


endmodule

`endif
