`ifndef __MULTIPLIER_TOP_SV
`define __MULTIPLIER_TOP_SV



`include "include/interface.svh"
`include "pipeline/execute/mult/multiplier_32x32.sv"
// FIXME: MULH not supported
module multiplier_top (
	input logic clk, reset,
	input u64 a, b,
	input u1 is_signed,
	output u64 c
);
	u64 A, B, C;
	u64 [2:0] p, p_nxt;
	assign A = (is_signed & a[63]) ? -a:a;
	assign B = (is_signed & b[63]) ? -b:b;
	multiplier_32x32 mult_inst1 (
		.clk, .reset,
		.a(A[31:0]),
		.b(B[31:0]),
		.c(p_nxt[0])
	);

	multiplier_32x32 mult_inst2 (
		.clk, .reset,
		.a(A[63:32]),
		.b(B[31:0]),
		.c(p_nxt[1])
	);

	multiplier_32x32 mult_inst3 (
		.clk, .reset,
		.a(A[31:0]),
		.b(B[63:32]),
		.c(p_nxt[2])
	);

	always_ff @(posedge clk) begin
		if (reset) begin
			p <= '0;
		end else begin
			p[0] <= {p_nxt[0]};
			p[1] <= {p_nxt[1][31:0], 32'b0};
			p[2] <= {p_nxt[2][31:0], 32'b0};
		end
	end
	assign C = p[0] + p[1] + p[2];
	assign c = (is_signed & (a[63] ^ b[63])) ? -C:C;

endmodule


`endif