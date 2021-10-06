`ifndef __DECODER_SV
`define __DECODER_SV

`ifdef VERILATOR
`include "include/interface.svh"
`else
`include "interface.svh"
`endif

module decoder 
	import common::*;
	import decode_pkg::*;(
	input u32 raw_instr,
	output decoded_instr_t instr
);
	op_t raw_op;
	assign raw_op = raw_instr[6:0];

	f7_t f7;
	assign f7 = raw_instr[31:25];

	f6_t f6;
	assign f6 = raw_instr[31:26];

	f3_t f3;
	assign f3 = raw_instr[14:12];

	creg_addr_t rs1, rs2, rd;
	assign rs1 = raw_instr[19:15];
	assign rs2 = raw_instr[24:20];
	assign rd = raw_instr[11:7];

	u1 sign_bit;
	assign sign_bit = raw_instr[31];

	u64 imm_itype;
	assign imm_itype = {{52{sign_bit}}, raw_instr[31:20]};

	u64 imm_stype;
	assign imm_stype = {{52{sign_bit}}, raw_instr[31:25], raw_instr[11:7]};

	u64 imm_btype;
	assign imm_btype = {{51{sign_bit}}, raw_instr[31], raw_instr[7], raw_instr[30:25], raw_instr[11:8], 1'b0};

	u64 imm_utype;
	assign imm_utype = {{32{sign_bit}}, raw_instr[31:12], 12'b0};

	u64 imm_jtype;
	assign imm_jtype = {{43{sign_bit}}, raw_instr[31], raw_instr[19:12], raw_instr[20], raw_instr[30:21], 1'b0};

	u64 imm_ztype;
	assign imm_ztype = {59'b0, raw_instr[19:15]};
	decoded_op_t op;
	control_t ctl;

	always_comb begin
		op = decoded_op_t'(0);
		ctl = '0;
		unique case(raw_op)
			OP_R: begin
				if (f7 == F7_MUL) begin
					unique case(f3)
						F3_MUL: begin
							ctl.regwrite = 1'b1;
							ctl.is_multdiv = 1'b1;
							ctl.mult_type = MULT_MUL;
						end
						F3_MULH: begin
							
						end
						F3_MULHSU: begin
							
						end
						F3_MULHU: begin
							
						end
						F3_DIV: begin
							ctl.regwrite = 1'b1;
							ctl.is_multdiv = 1'b1;
							ctl.mult_type = MULT_DIV;
						end
						F3_DIVU: begin
							ctl.regwrite = 1'b1;
							ctl.is_multdiv = 1'b1;
							ctl.mult_type = MULT_DIVU;
						end
						F3_REM: begin
							ctl.regwrite = 1'b1;
							ctl.is_multdiv = 1'b1;
							ctl.mult_type = MULT_REM;
						end
						F3_REMU: begin
							ctl.regwrite = 1'b1;
							ctl.is_multdiv = 1'b1;
							ctl.mult_type = MULT_REMU;
						end
						default: begin
							
						end
					endcase
				end
				else unique case(f3)
					F3_ADD_SUB: begin
						unique case(f7)
							F7_ADD: begin
								op = ADD;
								ctl.alufunc = ALU_ADD;
								ctl.regwrite = 1'b1;
							end
							F7_SUB: begin
								op = SUB;
								ctl.alufunc = ALU_SUB;
								ctl.regwrite = 1'b1;
							end
							default: begin
								
							end
						endcase
					end
					F3_SLL: begin
						op = SLL;
						ctl.alufunc = ALU_SLL;
						ctl.regwrite = 1'b1;
					end
					F3_SLT: begin
						op = SLT;
						ctl.alufunc = ALU_SLT;
						ctl.regwrite = 1'b1;
					end
					F3_SLTU: begin
						op = SLTU;
						ctl.alufunc = ALU_SLTU;
						ctl.regwrite = 1'b1;
					end
					F3_XOR: begin
						op = XOR;
						ctl.alufunc = ALU_XOR;
						ctl.regwrite = 1'b1;
					end
					F3_SRL_SRA: begin
						unique case(f6)
							F6_SRL: begin
								op = SRL;
								ctl.alufunc = ALU_SRL;
								ctl.regwrite = 1'b1;
							end
							F6_SRA: begin
								op = SRA;
								ctl.alufunc = ALU_SRA;
								ctl.regwrite = 1'b1;
							end
							default: begin
								
							end
						endcase
					end
					F3_OR: begin
						op = OR;
						ctl.alufunc = ALU_OR;
						ctl.regwrite = 1'b1;
					end
					F3_AND: begin
						op = AND;
						ctl.alufunc = ALU_AND;
						ctl.regwrite = 1'b1;
					end
					default: begin
						
					end
				endcase
				
			end
			OP_RI: begin
				unique case(f3)
					F3_ADD_SUB: begin
						op = ADDI;
						ctl.alufunc = ALU_ADD;
						ctl.regwrite = 1'b1;
						ctl.imm_as_src2 = 1'b1;
						ctl.imm_type = IMM_I;
					end
					F3_SLL: begin
						op = SLLI;
						ctl.alufunc = ALU_SLL;
						ctl.regwrite = 1'b1;
						ctl.imm_as_src2 = 1'b1;
						ctl.imm_type = IMM_I;
					end
					F3_SLT: begin
						op = SLTI;
						ctl.alufunc = ALU_SLT;
						ctl.regwrite = 1'b1;
						ctl.imm_as_src2 = 1'b1;
						ctl.imm_type = IMM_I;
					end
					F3_SLTU: begin
						op = SLTU;
						ctl.alufunc = ALU_SLTU;
						ctl.regwrite = 1'b1;
						ctl.imm_as_src2 = 1'b1;
						ctl.imm_type = IMM_I;
					end
					F3_XOR: begin
						op = XORI;
						ctl.alufunc = ALU_XOR;
						ctl.regwrite = 1'b1;
						ctl.imm_as_src2 = 1'b1;
						ctl.imm_type = IMM_I;
					end
					F3_SRL_SRA: begin
						unique case(f6)
							F6_SRL: begin
								op = SRLI;
								ctl.alufunc = ALU_SRL;
								ctl.regwrite = 1'b1;
								ctl.imm_as_src2 = 1'b1;
								ctl.imm_type = IMM_I;
							end
							F6_SRA: begin
								op = SRAI;
								ctl.alufunc = ALU_SRA;
								ctl.regwrite = 1'b1;
								ctl.imm_as_src2 = 1'b1;
								ctl.imm_type = IMM_I;
							end
							default: begin
								
							end
						endcase
					end
					F3_OR: begin
						op = ORI;
						ctl.alufunc = ALU_OR;
						ctl.regwrite = 1'b1;
						ctl.imm_as_src2 = 1'b1;
						ctl.imm_type = IMM_I;
					end
					F3_AND: begin
						op = ANDI;
						ctl.alufunc = ALU_AND;
						ctl.regwrite = 1'b1;
						ctl.imm_as_src2 = 1'b1;
						ctl.imm_type = IMM_I;
					end
					default: begin
						
					end
				endcase
			end
			OP_RIW: begin
				unique case(f3)
					F3_ADD_SUB: begin
						op = ADDIW;
						ctl.alufunc = ALU_ADDW;
						ctl.regwrite = 1'b1;
						ctl.imm_as_src2 = 1'b1;
						ctl.imm_type = IMM_I;
					end
					F3_SLL: begin
						op = SLLIW;
						ctl.alufunc = ALU_SLLW;
						ctl.regwrite = 1'b1;
						ctl.imm_as_src2 = 1'b1;
						ctl.imm_type = IMM_I;
					end
					F3_SRL_SRA: begin
						unique case(f7)
							F7_SRL: begin
								op = SRLI;
								ctl.alufunc = ALU_SRLW;
								ctl.regwrite = 1'b1;
								ctl.imm_as_src2 = 1'b1;
								ctl.imm_type = IMM_I;
							end
							F7_SRA: begin
								op = SRA;
								ctl.alufunc = ALU_SRAW;
								ctl.regwrite = 1'b1;
								ctl.imm_as_src2 = 1'b1;
								ctl.imm_type = IMM_I;
							end
							default: begin
								
							end
						endcase
					end
					default: begin
						
					end
				endcase
			end
			OP_RW: begin
				if (f7 == F7_MUL) begin
					unique case(f3)
						F3_MUL: begin
							ctl.regwrite = 1'b1;
							ctl.is_multdiv = 1'b1;
							ctl.mult_type = MULT_MULW;
						end
						F3_MULH: begin
							
						end
						F3_MULHSU: begin
							
						end
						F3_MULHU: begin
							
						end
						F3_DIV: begin
							ctl.regwrite = 1'b1;
							ctl.is_multdiv = 1'b1;
							ctl.mult_type = MULT_DIVW;
						end
						F3_DIVU: begin
							ctl.regwrite = 1'b1;
							ctl.is_multdiv = 1'b1;
							ctl.mult_type = MULT_DIVUW;
						end
						F3_REM: begin
							ctl.regwrite = 1'b1;
							ctl.is_multdiv = 1'b1;
							ctl.mult_type = MULT_REMW;
						end
						F3_REMU: begin
							ctl.regwrite = 1'b1;
							ctl.is_multdiv = 1'b1;
							ctl.mult_type = MULT_REMUW;
						end
						default: begin
							
						end
					endcase
				end
				else unique case(f3)
					F3_ADD_SUB: begin
						unique case(f7)
							F7_ADD: begin
								op = ADDW;
								ctl.alufunc = ALU_ADDW;
								ctl.regwrite = 1'b1;
							end
							F7_SUB: begin
								op = SUBW;
								ctl.alufunc = ALU_SUBW;
								ctl.regwrite = 1'b1;
							end
							default: begin
								
							end
						endcase
					end
					F3_SLL: begin
						op = SLLW;
						ctl.alufunc = ALU_SLLW;
						ctl.regwrite = 1'b1;
					end
					F3_SRL_SRA: begin
						unique case(f7)
							F7_SRL: begin
								op = SRLW;
								ctl.alufunc = ALU_SRLW;
								ctl.regwrite = 1'b1;
							end
							F7_SRA: begin
								op = SRAW;
								ctl.alufunc = ALU_SRAW;
								ctl.regwrite = 1'b1;
							end
							default: begin
								
							end
						endcase
					end
					default: begin
						
					end
				endcase
			end
			OP_LUI: begin
				op = LUI;
				ctl.alufunc = ALU_PASSB;
				ctl.imm_type = IMM_U;
				ctl.regwrite = 1'b1;
				ctl.imm_as_src2 = 1'b1;
			end
			OP_JAL: begin
				op = JAL;
				ctl.imm_type = IMM_J;
				ctl.regwrite = 1'b1;
				ctl.jump = 1'b1;
				ctl.link = 1'b1;
			end
			OP_JALR: begin
				op = JALR;
				ctl.regwrite = 1'b1;
				ctl.jump = 1'b1;
				ctl.link = 1'b1;
				ctl.jr = 1'b1;
				if (f3 != 3'b000) begin
					// reserved instruction exception
				end
			end
			OP_B: begin
				unique case(f3)
					F3_BEQ: begin
						op = BEQ;
						ctl.branch = 1'b1;
						ctl.branch_type = B_BEQ;
					end
					F3_BNE: begin
						op = BNE;
						ctl.branch = 1'b1;
						ctl.branch_type = B_BNE;
					end
					F3_BLT: begin
						op = BLT;
						ctl.branch = 1'b1;
						ctl.branch_type = B_BLT;
					end
					F3_BGE: begin
						op = BGE;
						ctl.branch = 1'b1;
						ctl.branch_type = B_BGE;
					end
					F3_BLTU: begin
						op = BLTU;
						ctl.branch = 1'b1;
						ctl.branch_type = B_BLTU;
					end
					F3_BGEU: begin
						op = BGEU;
						ctl.branch = 1'b1;
						ctl.branch_type = B_BGEU;
					end
					default: begin
						
					end
				endcase
			end
			OP_AUIPC: begin
				op = AUIPC;
				ctl.alufunc = ALU_ADD;
				ctl.imm_type = IMM_U;
				ctl.regwrite = 1'b1;
				ctl.pc_as_src1 = 1'b1;
				ctl.imm_as_src2 = 1'b1;
			end
			OP_L: begin
				unique case(f3)
					F3_LB: begin
						op = LB;
						ctl.memread = 1'b1;
						ctl.regwrite = 1'b1;
						ctl.msize = MSIZE1;
						ctl.imm_type = IMM_I;
						ctl.imm_as_src2 = 1'b1;
						ctl.alufunc = ALU_ADD;
					end
					F3_LH: begin
						op = LH;
						ctl.memread = 1'b1;
						ctl.regwrite = 1'b1;
						ctl.msize = MSIZE2;
						ctl.imm_type = IMM_I;
						ctl.imm_as_src2 = 1'b1;
						ctl.alufunc = ALU_ADD;
					end
					F3_LW: begin
						op = LW;
						ctl.memread = 1'b1;
						ctl.regwrite = 1'b1;
						ctl.msize = MSIZE4;
						ctl.imm_type = IMM_I;
						ctl.imm_as_src2 = 1'b1;
						ctl.alufunc = ALU_ADD;
					end
					F3_LBU: begin
						op = LBU;
						ctl.memread = 1'b1;
						ctl.regwrite = 1'b1;
						ctl.msize = MSIZE1;
						ctl.imm_type = IMM_I;
						ctl.imm_as_src2 = 1'b1;
						ctl.alufunc = ALU_ADD;
						ctl.mem_unsigned = 1'b1;
					end
					F3_LHU: begin
						op = LHU;
						ctl.memread = 1'b1;
						ctl.regwrite = 1'b1;
						ctl.msize = MSIZE2;
						ctl.imm_type = IMM_I;
						ctl.imm_as_src2 = 1'b1;
						ctl.alufunc = ALU_ADD;
						ctl.mem_unsigned = 1'b1;
					end
					F3_LWU: begin
						op = LWU;
						ctl.memread = 1'b1;
						ctl.regwrite = 1'b1;
						ctl.msize = MSIZE4;
						ctl.imm_type = IMM_I;
						ctl.imm_as_src2 = 1'b1;
						ctl.alufunc = ALU_ADD;
						ctl.mem_unsigned = 1'b1;
					end
					F3_LD: begin
						op = LD;
						ctl.memread = 1'b1;
						ctl.regwrite = 1'b1;
						ctl.msize = MSIZE8;
						ctl.imm_type = IMM_I;
						ctl.imm_as_src2 = 1'b1;
						ctl.alufunc = ALU_ADD;
					end
					default: begin
						
					end
				endcase
			end
			OP_S: begin
				unique case(f3)
					F3_SB: begin
						op = SB;
						ctl.memwrite = 1'b1;
						ctl.imm_as_src2 = 1'b1;
						ctl.msize = MSIZE1;
						ctl.alufunc = ALU_ADD;
						ctl.imm_type = IMM_S;
					end
					F3_SH: begin
						op = SH;
						ctl.memwrite = 1'b1;
						ctl.imm_as_src2 = 1'b1;
						ctl.msize = MSIZE2;
						ctl.alufunc = ALU_ADD;
						ctl.imm_type = IMM_S;
					end
					F3_SW: begin
						op = SW;
						ctl.memwrite = 1'b1;
						ctl.imm_as_src2 = 1'b1;
						ctl.msize = MSIZE4;
						ctl.alufunc = ALU_ADD;
						ctl.imm_type = IMM_S;
					end
					F3_SD: begin
						op = SD;
						ctl.memwrite = 1'b1;
						ctl.imm_as_src2 = 1'b1;
						ctl.msize = MSIZE8;
						ctl.alufunc = ALU_ADD;
						ctl.imm_type = IMM_S;
					end
					default: begin
						
					end
				endcase
			end
			OP_FENCE: begin
				unique case(f3)
					F3_FENCE: begin
						
					end
					F3_FENCEI: begin
						
					end
					default: begin
						
					end
				endcase
			end
			OP_PRIV: begin
				unique case(f3)
					F3_ECALL_EBREAK: begin
						if (raw_instr == 32'b0011000_00010_00000_000_00000_1110011)
							ctl.is_mret = 1'b1;
					end
					F3_CSRRW: begin
						op = CSRRW;
						ctl.alufunc = ALU_PASSA;
						ctl.regwrite = 1'b1;
						ctl.csrwrite = 1'b1;
						ctl.csr_write_type = CSR_CSRRW;
					end
					F3_CSRRS: begin
						op = CSRRS;
						ctl.alufunc = ALU_PASSA;
						ctl.regwrite = 1'b1;
						ctl.csrwrite = 1'b1;
						ctl.csr_write_type = CSR_CSRRS;
					end
					F3_CSRRC: begin
						op = CSRRC;
						ctl.alufunc = ALU_PASSA;
						ctl.regwrite = 1'b1;
						ctl.csrwrite = 1'b1;
						ctl.csr_write_type = CSR_CSRRC;
					end
					F3_CSRRWI: begin
						op = CSRRWI;
						ctl.regwrite = 1'b1;
						ctl.alufunc = ALU_PASSB;
						ctl.csrwrite = 1'b1;
						ctl.csr_write_type = CSR_CSRRW;
						ctl.imm_as_src2 = 1'b1;
						ctl.imm_type = IMM_Z;
					end
					F3_CSRRSI: begin
						op = CSRRSI;
						ctl.regwrite = 1'b1;
						ctl.alufunc = ALU_PASSB;
						ctl.csrwrite = 1'b1;
						ctl.csr_write_type = CSR_CSRRS;
						ctl.imm_as_src2 = 1'b1;
						ctl.imm_type = IMM_Z;
					end
					F3_CSRRCI: begin
						op = CSRRCI;
						ctl.regwrite = 1'b1;
						ctl.alufunc = ALU_PASSB;
						ctl.csrwrite = 1'b1;
						ctl.csr_write_type = CSR_CSRRC;
						ctl.imm_as_src2 = 1'b1;
						ctl.imm_type = IMM_Z;
					end
					default: begin
						
					end
				endcase
			end
			default: begin
				
			end
		endcase
	end
	
	u64 imm;
	always_comb begin
		imm = 'x;
		unique case(ctl.imm_type)
			IMM_I: imm = imm_itype;
			IMM_B: imm = imm_btype;
			IMM_J: imm = imm_jtype;
			IMM_U: imm = imm_utype;
			IMM_S: imm = imm_stype;
			IMM_Z: imm = imm_ztype;
			default: begin
				
			end
		endcase
	end
	

	assign instr.op = op;
	assign instr.ctl = ctl;
	assign instr.src1 = rs1;
	assign instr.src2 = rs2;
	assign instr.dst = rd;
	assign instr.csr_addr = raw_instr[31:20];
	assign instr.imm = imm;
endmodule



`endif