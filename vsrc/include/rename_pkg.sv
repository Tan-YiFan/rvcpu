`ifndef __RENAME_PKG_SV
`define __RENAME_PKG_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif

package rename_pkg;
	import common::*;
	import decode_pkg::*;
	import config_pkg::*;
	typedef struct packed {
		u1 valid;
		preg_addr_t id;
	} rat_entry_t;

	typedef struct packed {
		u1 valid;
		creg_addr_t src;
		preg_addr_t psrc;
	} rat_wreq_t;
	typedef union packed{
        struct packed {
            word_t data;
        } alu;
        struct packed {
            vaddr_t addr;
        } mem;
        struct packed {
        	logic [30:0] zeros;
            logic branch_taken;
            pc_t pc;
			word_t data;
        } branch;
        struct packed {
            word_t data;
        } mult;
    } entry_data_t;

	typedef struct packed{
        logic complete;
        preg_addr_t preg;
        creg_addr_t creg;
        entry_data_t data;
	`ifdef VERILATOR
        pc_t pc;
	`endif
        control_t ctl;
	} rob_entry_t;

	typedef struct packed {
		struct packed {
			logic valid;
			preg_addr_t pdst;
			struct packed {
				logic valid;
				preg_addr_t id;
			} psrc1, psrc2;
			creg_addr_t dst, src1, src2;
			control_t ctl;
			decoded_op_t op;
			word_t imm;
			pc_t pc;
		} [FETCH_WIDTH-1:0] instr;
	} rename_data_t;
	
	
endpackage

`endif
