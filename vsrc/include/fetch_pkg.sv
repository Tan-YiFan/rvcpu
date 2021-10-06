`ifndef __FETCH_PKG_SV
`define __FETCH_PKG_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif
package fetch_pkg;
	import common::*;
	typedef struct packed {
		u32 raw_instr;
		u64 pc;
	} fetch_data_t;
endpackage

`endif