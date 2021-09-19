`ifndef __DIVIDER_TOP_SV
`define __DIVIDER_TOP_SV

`include "include/interface.svh"
`include "pipeline/execute/div/divider.sv"
module divider_top
	import common::*;(
	input logic clk, reset,
	input u64 a, b,
	input logic is_signed,
	input logic get_div,
	output u64 c,
	input logic valid
);

	u128 out;
	u64 a_u, b_u;
	assign a_u = (is_signed & a[63]) ? -a:a;
	assign b_u = (is_signed & b[63]) ? -b:b;

	/* |b| = |aq| + |r|
	*   1) b > 0, a < 0 ---> b = (-a)(-q) + r
	*   2) b < 0, a > 0 ---> -b = a(-q) + (-r) */
	u64 hi, lo;
	assign lo = (is_signed & (a[63] ^ b[63])) ? -out[63:0] : out[63:0];
	assign hi = (is_signed & (a[63] ^ out[127])) ? -out[127:64] : out[127:64];
	
	divider divider_inst(.a(a_u), .b(b_u), .c(out), .clk, .reset, .valid);
	assign c = get_div ? lo : hi;
endmodule



`endif
