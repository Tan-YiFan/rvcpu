`ifndef __WRITEBACK_PKG_SV
`define __WRITEBACK_PKG_SV

`include "include/common.sv"
`include "include/config.sv"
`include "include/decode_pkg.sv"
package writeback_pkg;
	import common::*;
	import decode_pkg::*;
	import config_pkg::*;
	typedef struct packed {
		decoded_instr_t instr;
		word_t result;
		creg_addr_t[AREG_WRITE_PORTS-1:0] writereg;
	} writeback_data_t;
	
endpackage

`endif
