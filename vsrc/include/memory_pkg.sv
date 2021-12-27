`ifndef __MEMORY_PKG_SV
`define __MEMORY_PKG_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/decode_pkg.sv"
`endif
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

	typedef struct packed {
		u1 valid;
		msize_t msize;
		u64 addr;
		u64 data;
		rob_addr_t rob_addr;
	} wbuffer_entry_t;

	typedef wbuffer_entry_t wbuffer_wreq_t;
	
	typedef struct packed {
		u1 valid;
		rob_addr_t rob_addr;
	} wbuffer_creq_t;
	
	typedef struct packed {
		
	} wbuffer_rreq_t;
	
	typedef struct packed {
		
	} wbuffer_rresp_t;
	

	
endpackage

`endif
