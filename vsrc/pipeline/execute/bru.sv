`ifndef __BRU_SV
`define __BRU_SV


`ifdef VERILATOR
`include "include/interface.svh"
`else
`include "interface.svh"
`endif

module bru 
	import common::*;
	import decode_pkg::*;(
	input control_t ctl,
	input pc_t pc, pcjump,
	input u1 jump,
	input u64 a, b, imm, csr,
	output word_t data,
	output word_t extra
);
	// extra
	u1 pd_fail;
	pc_t pc_correct;

	u1 branch_taken;
	always_comb begin
		branch_taken = 1'b0;
		unique case(ctl.branch_type)
			B_BEQ: begin
				branch_taken = a == b;
			end
			B_BNE: begin
				branch_taken = a != b;
			end
			B_BLT: begin
				branch_taken = $signed(a) < $signed(b);
			end
			B_BGE: begin
				branch_taken = $signed(a) >= $signed(b);
			end
			B_BLTU: begin
				branch_taken = a < b;
			end
			B_BGEU: begin
				branch_taken = a >= b;
			end
			default: begin
				
			end
		endcase
	end

	always_comb begin
		pc_correct = 'x;
		unique case(1'b1)
			ctl.branch: pc_correct = pc + imm;
			ctl.jump: pc_correct = ctl.jr ? a + imm : pc + imm;
			ctl.is_mret: pc_correct = csr;
			default: begin
				
			end
		endcase
	end

	word_t csrout;
	always_comb begin
		csrout = 'x;
		unique case(ctl.csr_write_type)
			CSR_CSRRC: begin
				csrout = csr & ~a;
			end
			CSR_CSRRW: begin
				csrout = a;
			end
			CSR_CSRRS: begin
				csrout = csr | a;
			end
			default: begin
				
			end
		endcase
	end
	assign pd_fail = (jump != (ctl.jump | branch_taken)) || pcjump != pc_correct;
	assign data = ctl.csrwrite ? csr : pc + 4;
	assign extra = ctl.csrwrite ? csrout : {
		pd_fail,
		pc_correct
	};
	
endmodule



`endif