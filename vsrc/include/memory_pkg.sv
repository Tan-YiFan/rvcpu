`ifndef __MEMORY_PKG_SV
`define __MEMORY_PKG_SV

`include "include/common.sv"
`include "include/decode_pkg.sv"

package memory_pkg;
	import common::*;
	import decode_pkg::*;

	typedef struct packed {
		decoded_instr_t instr;
		word_t rd;
		u64 result;
		creg_addr_t writereg;
		u64 pcplus4;
		u64 csr;
	} memory_data_t;
	
	
endpackage

`endif
