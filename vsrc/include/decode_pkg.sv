`ifndef DECODE_PKG_SV
`define DECODE_PKG_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif
package decode_pkg;
	import common::*;
	import config_pkg::*;

	/*
	 * R-type:
	 * [31:25] funct7
	 * [24:20] rs2
	 * [19:15] rs1
	 * [14:12] funct3
	 * [11:7]  rd
	 * [6:0] opcode
	 *
	 * I-type:
	 * [31:20] imm[11:0]
	 * [19:15] rs1
	 * [14:12] funct3
	 * [11:7] rd
	 * [6:0] opcode
	 *
	 * S-type:
	 * [31:25] imm[11:5]
	 * [24:20] rs2
	 * [19:15] rs1
	 * [14:12] funct3
	 * [11:7] imm[4:0]
	 * [6:0] opcode
	 *
	 * B-type:
	 * [31] imm[12]
	 * [30:25] imm[10:5]
	 * [24:20] rs2
	 * [19:15] rs1
	 * [14:12] funct3
	 * [11:8] imm[4:1]
	 * [7] imm[11]
	 * [6:0] opcode
	 *
	 * U-type:
	 * [31:12] imm[31:12]
	 * [11:7] rd
	 * [6:0] opcode
	 *
	 * J-type:
	 * [31] imm[20]
	 * [30:21] imm[10:1]
	 * [20] imm[11]
	 * [19:12] imm[19:12]
	 * [11:7] rd
	 * [6:0] opcode
	 */
	
	// parameters

	// opcode
	parameter u7 OP_R     = 7'b0110011;
	parameter u7 OP_RI    = 7'b0010011;
	parameter u7 OP_RIW   = 7'b0011011;
	parameter u7 OP_RW    = 7'b0111011;
	parameter u7 OP_LUI   = 7'b0110111;
	parameter u7 OP_JAL   = 7'b1101111;
	parameter u7 OP_JALR  = 7'b1100111;
	parameter u7 OP_B     = 7'b1100011;
	parameter u7 OP_AUIPC = 7'b0010111;
	parameter u7 OP_L     = 7'b0000011;
	parameter u7 OP_S     = 7'b0100011;
	parameter u7 OP_FENCE = 7'b0001111;
	parameter u7 OP_PRIV  = 7'b1110011;

	// func7
	// add, sub
	parameter u7 F7_ADD = 7'b0000000;
	parameter u7 F7_SUB = 7'b0100000;
	// sra, srl
	parameter u7 F7_SRL = 7'b0000000;
	parameter u7 F7_SRA = 7'b0100000;
	parameter u6 F6_SRL = 6'b000000;
	parameter u6 F6_SRA = 6'b010000;
	// multiply
	parameter u7 F7_MUL = 7'b0000001;

	// func3
	// B type
	parameter u3 F3_BEQ = 3'b000;
	parameter u3 F3_BNE = 3'b001;
	parameter u3 F3_BLT = 3'b100;
	parameter u3 F3_BGE = 3'b101;
	parameter u3 F3_BLTU = 3'b110;
	parameter u3 F3_BGEU = 3'b111;
	// Load
	parameter u3 F3_LB = 3'b000;
	parameter u3 F3_LH = 3'b001;
	parameter u3 F3_LW = 3'b010;
	parameter u3 F3_LBU = 3'b100;
	parameter u3 F3_LHU = 3'b101;
	parameter u3 F3_LWU = 3'b110;
	parameter u3 F3_LD = 3'b011;
	// Save
	parameter u3 F3_SB = 3'b000;
	parameter u3 F3_SH = 3'b001;
	parameter u3 F3_SW = 3'b010;
	parameter u3 F3_SD = 3'b011;
	// Fence
	parameter u3 F3_FENCE = 3'b000;
	parameter u3 F3_FENCEI = 3'b001;
	// Priv
	parameter u3 F3_ECALL_EBREAK = 3'b000;
	parameter u3 F3_CSRRW = 3'b001;
	parameter u3 F3_CSRRS = 3'b010;
	parameter u3 F3_CSRRC = 3'b011;
	parameter u3 F3_CSRRWI = 3'b101;
	parameter u3 F3_CSRRSI = 3'b110;
	parameter u3 F3_CSRRCI = 3'b111;
	// Arith
	parameter u3 F3_ADD_SUB = 3'b000;
	parameter u3 F3_SLL = 3'b001;
	parameter u3 F3_SLT = 3'b010;
	parameter u3 F3_SLTU = 3'b011;
	parameter u3 F3_XOR = 3'b100;
	parameter u3 F3_SRL_SRA = 3'b101;
	parameter u3 F3_OR = 3'b110;
	parameter u3 F3_AND = 3'b111;
	// Multiply and Divide
	parameter u3 F3_MUL = 3'b000;
	parameter u3 F3_MULH = 3'b001;
	parameter u3 F3_MULHSU = 3'b010;
	parameter u3 F3_MULHU = 3'b011;
	parameter u3 F3_DIV = 3'b100;
	parameter u3 F3_DIVU = 3'b101;
	parameter u3 F3_REM = 3'b110;
	parameter u3 F3_REMU = 3'b111;



	// typedefs
	typedef u7 op_t;
	typedef u7 f7_t;
	typedef u6 f6_t;
	typedef u3 f3_t;

	
	typedef enum u7 {
		LUI, AUIPC, JAL, JALR,
		BEQ, BNE, BLT, BGE, BLTU, BGEU,
		LB, LH, LW, LBU, LHU, LD, LWU,
		SB, SH, SW, SD,
		FENCE, FENCEI,
		ECALL, EBREAK,
		CSRRW, CSRRS, CSRRC,
		CSRRWI, CSRRSI, CSRRCI,
		ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND,
		ADDI, SLLI, SLTI, SLTIU, XORI, SRLI, SRAI, ORI, ANDI,
		ADDW, SUBW, SLLW, SRLW, SRAW,
		ADDIW, SLLIW, SRLIW, SRAIW,
		MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU, MULW
	} decoded_op_t;
	
	typedef enum u5 {
		ALU_ADD, ALU_ADDW, ALU_SUB, ALU_SUBW, ALU_SLL, ALU_SLLW,
		ALU_SRA, ALU_SRAW, ALU_SRL, ALU_SRLW,
		ALU_AND, ALU_OR, ALU_XOR, ALU_PASSB,
		ALU_SLT, ALU_SLTU, ALU_PASSA
	} alufunc_t;
	
	typedef enum u4 {
		MULT_MUL, MULT_MULH, MULT_MULHSU, MULT_MULHU,
		MULT_DIV, MULT_DIVU, MULT_REM, MULT_REMU, MULT_MULW,
		MULT_DIVW, MULT_DIVUW, MULT_REMW, MULT_REMUW
	} mult_t;

	typedef enum u3 {
		IMM_I, IMM_B, IMM_U, IMM_J, IMM_S, IMM_Z
	} imm_t;

	typedef enum u3 {
		B_BEQ, B_BNE, B_BLT, B_BGE, B_BLTU, B_BGEU
	} branch_t;
	typedef enum u2 {
		CSR_CSRRC, CSR_CSRRS, CSR_CSRRW
	} csr_write_t;
	
	
	typedef struct packed {
		alufunc_t alufunc;
		u1 memread, memwrite;
		u1 regwrite;
		imm_t imm_type;
		u1 pc_as_src1;
		u1 imm_as_src2;
		u1 jump;
		u1 link;
		u1 jr;
		u1 branch;
		branch_t branch_type;
		msize_t msize;
		u1 mem_unsigned;
		mult_t mult_type;
		u1 csrwrite;
		csr_write_t csr_write_type;
		u1 is_multdiv;
		u1 is_mret;
	} control_t;
	
	typedef struct packed {
		decoded_op_t op;
		control_t ctl;
		creg_addr_t src1, src2, dst;
		csr_addr_t csr_addr;
		word_t imm;
	} decoded_instr_t;
	
	typedef struct packed {
		struct packed {
			u1 valid;
			decoded_instr_t instr;
			u64 pc;
		} [FETCH_WIDTH-1:0] instr;
	} decode_data_t;
	
	

endpackage
`endif