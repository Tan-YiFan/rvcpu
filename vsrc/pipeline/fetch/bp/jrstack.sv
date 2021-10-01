`ifndef __JRSTACK_SV
`define __JRSTACK_SV

`ifdef VERILATOR

`endif

module jrstack #(

) (
	input logic clk, reset,

);

	localparam type counter_t = u16;
	localparam type entry_t = struct packed {
		
		counter_t counter;
	};

endmodule


`endif
