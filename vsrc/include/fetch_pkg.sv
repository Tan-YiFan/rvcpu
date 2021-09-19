`ifndef __FETCH_PKG_SV
`define __FETCH_PKG_SV

`include "include/common.sv"

package fetch_pkg;
	import common::*;
	typedef struct packed {
		u32 raw_instr;
		u64 pc;
	} fetch_data_t;
endpackage

`endif