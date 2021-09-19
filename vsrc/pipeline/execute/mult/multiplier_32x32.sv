`ifndef __MULTIPLIER_32X32_SV
`define __MULTIPLIER_32X32_SV

`include "include/interface.svh"

module multiplier_32x32 (
	input logic clk, reset,
	input u32 a, b,
	output u64 c
);
	logic [3:0][31:0]p, p_nxt;
	assign p_nxt[0] = a[15:0] * b[15:0];
	assign p_nxt[1] = a[15:0] * b[31:16];
	assign p_nxt[2] = a[31:16] * b[15:0];
	assign p_nxt[3] = a[31:16] * b[31:16];

	always_ff @(posedge clk) begin
		if (reset) begin
			p <= '0;
		end else begin
			p <= p_nxt;
		end
	end
	logic [3:0][63:0] q;
	assign q[0] = {32'b0, p[0]};
	assign q[1] = {16'b0, p[1], 16'b0};
	assign q[2] = {16'b0, p[2], 16'b0};
	assign q[3] = {p[3], 32'b0};
	assign c = q[0] + q[1] + q[2] + q[3];
endmodule



`endif
