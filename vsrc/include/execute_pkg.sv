`ifndef __EXECUTE_PKG_SV
`define __EXECUTE_PKG_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/decode_pkg.sv"
`include "include/commit_pkg.sv"
`endif
package execute_pkg;

	import common::*;
	import decode_pkg::*;
	import commit_pkg::*;
	typedef struct packed {
		commit_instr_t [3:0] alu_commit;
		commit_instr_t [1:0] mem_commit;
		commit_instr_t [0:0] br_commit;
		commit_instr_t [0:0] mul_commit;
	} execute_data_t;
	
endpackage

`endif
