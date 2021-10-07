`ifndef __SOURCE_PKG_SV
`define __SOURCE_PKG_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/decode_pkg.sv"
`include "include/issue_pkg.sv"
`endif

package source_pkg;
	import common::*;
	import decode_pkg::*;
	import issue_pkg::*;
	typedef struct packed {
		logic valid;
        word_t d1, d2, imm;
		creg_addr_t src1, src2;
        preg_addr_t psrc1, psrc2, dst;
        logic forward_en1, forward_en2;
        control_t ctl;
        // decoded_op_t op;
        pc_t pc;
		// u1 jump;
		// pc_t pcjump;
	} source_instr_t;

	typedef struct packed {
		source_instr_t[4-1:0] alu_source;
        source_instr_t[2-1:0] mem_source;
        source_instr_t[1-1:0] branch_source;
        source_instr_t[1-1:0] mult_source;
		word_t csr;
	} source_data_t;
	

endpackage

`endif
