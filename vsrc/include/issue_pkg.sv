`ifndef __ISSUE_PKG_SV
`define __ISSUE_PKG_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/decode_pkg.sv"
`endif

package issue_pkg;
	import common::*;
	import decode_pkg::*;
	// parameter BRAODCAST_NUM = 10;
	// parameter WAKE_NUM = BRAODCAST_NUM + 4;
	parameter WAKE_NUM = 8 + 4;
	parameter ALU_WAKE_NUM = 4 + 4 + 4 + 8 + 4;


	typedef struct packed {
        logic valid;
		creg_addr_t id;
        preg_addr_t pid;
        // word_t data;
        logic forward_en;
    } src_data_t;
	typedef struct packed {
		u1 valid;
		src_data_t src1, src2;
		rob_ptr_t dst;
		control_t ctl;
        word_t imm;
		pc_t pc;
        // decoded_op_t op;
		// u1 jump;
		// pc_t pcjump;
	} iq_entry_t;
	
	typedef struct packed {
        u1 valid;
        iq_entry_t entry;
    } write_req_t;
    typedef struct packed {
        u1 valid;
        preg_addr_t id;
    } wake_req_t;
    // read
    typedef struct packed {
        iq_entry_t entry;
    } read_resp_t;

	typedef struct packed {
        logic valid;
        word_t imm;
		creg_addr_t src1, src2;
        preg_addr_t psrc1, psrc2, dst;
        logic forward_en1, forward_en2;
        control_t ctl;
        // decoded_op_t op;
        pc_t pc;
		// u1 jump;
		// pc_t pcjump;
    } issued_instr_t;
	typedef struct packed {
		issued_instr_t[4-1:0] alu_issue;
        issued_instr_t[2-1:0] mem_issue;
        issued_instr_t[1-1:0] branch_issue;
        issued_instr_t[1-1:0] mult_issue;
	} issue_data_t;
	
	
endpackage

`endif
