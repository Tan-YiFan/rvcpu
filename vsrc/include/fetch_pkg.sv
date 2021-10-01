`ifndef __FETCH_PKG_SV
`define __FETCH_PKG_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif
package fetch_pkg;
	import common::*;
	import config_pkg::*;
	typedef struct packed {
		struct packed {
			u1 valid;
			u32 raw_instr;
			u64 pc;
			u1 jump;
			
		} [FETCH_WIDTH-1:0] instr;
	} fetch_data_t;
endpackage

`endif