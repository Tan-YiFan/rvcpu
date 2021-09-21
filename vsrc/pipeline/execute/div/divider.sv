`ifndef __DIVIDER_SV
`define __DIVIDER_SV

`ifdef VERILATOR
`include "include/interface.svh"
`else
`include "interface.svh"
`endif
module divider(
	input logic clk, reset, valid,
	input u64 a, b,
	output u128 c // c = {a % b, a / b}
);
	enum i1 { INIT, DOING } state, state_nxt;
	u10 count, count_nxt;
	localparam u10 DIV_DELAY = 65;
	always_ff @(posedge clk) begin
		if (reset | ~valid) begin
			{state, count} <= '0;
		end else begin
			{state, count} <= {state_nxt, count_nxt};
		end
	end
	always_comb begin
		{state_nxt, count_nxt} = {state, count}; // default
		unique case(state)
			INIT: begin
				if (valid) begin
					state_nxt = DOING;
					count_nxt = DIV_DELAY;
				end
			end
			DOING: begin
				count_nxt = count - 1;
				if (count_nxt == '0) begin
					state_nxt = INIT;
				end
			end
		endcase
	end
	u128 p, p_nxt;
	u64 b_nxt;
	always_comb begin
		p_nxt = p;
		unique case(state)
			INIT: begin
				p_nxt = {64'b0, a};
			end
			DOING: begin
				p_nxt = {p_nxt[126:0], 1'b0};
				if (p_nxt[127:64] >= b_nxt) begin
					p_nxt[127:64] -= b_nxt;
					p_nxt[0] = 1'b1;
				end
			end
		endcase
	end
	always_ff @(posedge clk) begin
		if (reset | ~valid) begin
			p <= '0;
			b_nxt <= '0;
		end else begin
			p <= p_nxt;
			if (state == INIT)
			b_nxt <= b;
		end
	end
	assign c = p;
endmodule



`endif
