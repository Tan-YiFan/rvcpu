
`ifndef __ALU_SV
`define __ALU_SV
`include "include/interface.svh"

module alu
	import common::*;
	import decode_pkg::*; (
	input u64 a, b,
	input alufunc_t alufunc,
	output u64 c
);

	u32 temp;
	always_comb begin
		c = 'x;
		temp = 'x;
		unique case(alufunc)
			ALU_ADD: begin
				c = a + b;
			end
			ALU_ADDW: begin
				temp = a[31:0] + b[31:0];
				c = {{32{temp[31]}}, temp};
			end
			ALU_SUB: begin
				c = a - b;
			end
			ALU_SUBW: begin
				temp = a[31:0] - b[31:0];
				c = {{32{temp[31]}}, temp};
			end
			ALU_SLL: begin
				c = a << b[5:0];
			end
			ALU_SLLW: begin
				temp = a[31:0] << b[4:0];
				c = {{32{temp[31]}}, temp};
			end
			ALU_SRL: begin
				c = a >> b[5:0];
			end
			ALU_SRLW: begin
				temp = a[31:0] >> b[4:0];
				c = {{32{temp[31]}}, temp};
			end
			ALU_SRA: begin
				c = $signed(a) >>> b[5:0];
			end
			ALU_SRAW: begin
				temp = $signed(a[31:0]) >>> b[4:0];
				c = {{32{temp[31]}}, temp};
			end
			ALU_PASSB: begin
				c = b;
			end
			ALU_OR: begin
				c = a | b;
			end
			ALU_XOR: begin
				c = a ^ b;
			end
			ALU_AND: begin
				c = a & b;
			end
			ALU_SLT: begin
				c = $signed(a) < $signed(b);
			end
			ALU_SLTU: begin
				c = a < b;
			end
			default: begin
				c = 'x;
			end
		endcase
	end
	
endmodule


`endif