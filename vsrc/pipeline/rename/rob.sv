`ifndef __ROB_SV
`define __ROB_SV

`ifdef VERILATOR

`else

`endif

module rob
	import common::*;
	import rename_pkg::*;(
	input logic clk, reset,
	rename_intf.rob rename,
    commit_intf.rob commit,
	retire_intf.rob retire,
    payloadRAM_intf.rob payloadRAM,
    hazard_intf.rob hazard,
    pcselect_intf.rob pcselect,
);


endmodule


`endif
