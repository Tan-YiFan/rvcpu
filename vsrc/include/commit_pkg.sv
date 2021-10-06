`ifndef __COMMIT_PKG_SV
`define __COMMIT_PKG_SV

`ifdef VERILATOR

`endif

package commit_pkg;
	import common::*;
	typedef struct packed {
		u1 valid;
		word_t data;
		word_t extra;
		preg_addr_t dst;
	} commit_instr_t;
	
endpackage

`endif
