`ifndef __EXECUTE_PKG_SV
`define __EXECUTE_PKG_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/decode_pkg.sv"
`endif
package execute_pkg;

	import common::*;
	import decode_pkg::*;
	typedef struct packed {
		decoded_instr_t instr;
		u64 result;
		u64 writedata;
		u64 csr;
		word_t pcplus4;
		creg_addr_t writereg;
	} execute_data_t;
	
endpackage

`endif
