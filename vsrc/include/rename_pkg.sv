`ifndef __RENAME_PKG_SV
`define __RENAME_PKG_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif

package rename_pkg;
	import common::*;
	import decode_pkg::*;
	import config_pkg::*;

	parameter R1_NUM = COMMIT_WIDTH;
	parameter R2_NUM = COMMIT_WIDTH + 2 * AREG_READ_PORTS;
	typedef struct packed {
		u1 valid;
		preg_addr_t id;
	} rat_entry_t;

	typedef struct packed {
		u1 valid;
		creg_addr_t src;
		preg_addr_t psrc;
	} rat_wreq_t;
	typedef union packed {
        struct packed {
			word_t extra;
            word_t data;
        } alu;
        struct packed {
			// word_t extra;
			struct packed {
				logic [63-1-32-$bits(strobe_t) - $bits(msize_t):0] zero;
				msize_t msize; // 
				strobe_t strobe; // 8
				u32 addr;
				u1 uncached;
			} extra;
            word_t data;
        } mem;
        struct packed {
			union packed {
				struct packed {
					u31 zero;
					u1 pd_fail;
					pc_t correct_pc;
				} branch;
				word_t csr;
			} extra;
        	word_t data;
        } branch;
        struct packed {
			word_t extra;
            word_t data;
        } mult;
    } entry_data_t;

	typedef struct packed{
        logic complete;
        preg_addr_t preg;
        creg_addr_t creg;
        entry_data_t data;
        pc_t pc;
        control_t ctl;
	} rob_entry_t;

	typedef struct packed {
		preg_addr_t preg;
        creg_addr_t creg;
		pc_t pc;
		control_t ctl;
	} rob_entry1_t;

	typedef struct packed {
		u1 valid;
		logic [$clog2(PREG_NUM/COMMIT_WIDTH)-1:0] addr;
		rob_entry1_t entry;
	} rob_entry1_write_req;

	typedef struct packed {
		entry_data_t data;
	} rob_entry2_t;
	
	typedef struct packed {
		u1 valid;
		logic [$clog2(PREG_NUM/COMMIT_WIDTH)-1:0] addr;
		rob_entry2_t entry;
	} rob_entry2_write_req;

	typedef struct packed {
		struct packed {
			logic valid;
			rob_ptr_t pdst;
			struct packed {
				logic valid;
				preg_addr_t id;
			} psrc1, psrc2;
			creg_addr_t dst, src1, src2;
			control_t ctl;
			decoded_op_t op;
			word_t imm;
			pc_t pc;
			u1 jump;
			pc_t pcjump;
		} [FETCH_WIDTH-1:0] instr;
	} rename_data_t;
	
	
endpackage

`endif
