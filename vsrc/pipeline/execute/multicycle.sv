`ifndef __MULTICYCLE_SV
`define __MULTICYCLE_SV

`ifdef VERILATOR
`include "include/interface.svh"
`include "pipeline/execute/div/divider_top.sv"
`include "pipeline/execute/mult/multiplier_top.sv"
`else
`include "interface.svh"
`endif
module multicycle (
	input logic clk, reset,
	input u64 a, b,
	input u1 is_multdiv,
	input u1 flush,
	input mult_t mult_type,
	output u64 c,
	output u1 mult_ok
);
	u64 c_m, c_d;
	divider_top divider_top_inst (
		.clk, .reset,
		.a, .b,
		.c(c_d),
		.is_signed(mult_type == MULT_DIV || mult_type == MULT_REM),
		.get_div(mult_type == MULT_DIV || mult_type == MULT_DIVU),
		.valid(is_multdiv)
	);

	multiplier_top multiplier_top_inst (
		.clk, .reset,
		.a, .b,
		.c(c_m),
		.is_signed(1'b1)
	);

	always_comb begin
		c = 'x;
		unique case(mult_type)
			MULT_MUL: begin
				c = c_m;
			end
			MULT_MULW: begin
				c = {{32{c_m[31]}}, c_m[31:0]};
			end
			MULT_DIV, MULT_DIVU, MULT_REM, MULT_REMU: begin
				c = c_d;
			end
			MULT_DIVW, MULT_DIVUW, MULT_REMW, MULT_REMUW: begin
				c = {{32{c_d[31]}}, c_d[31:0]};
			end
			default: begin
				
			end
		endcase
	end

	localparam MULT_DELAY = 2;
	localparam DIV_DELAY = 65;
	localparam type state_t = enum logic {INIT, DOING};
	state_t state, state_nxt;
	u7 counter, counter_nxt;
	always_ff @(posedge clk) begin
		if (reset | flush) begin
			state <= INIT;
			counter <= '0;
		end else begin
			state <= state_nxt;
			counter <= counter_nxt;
		end
	end

	always_comb begin : multicycle_counter
		state_nxt = state;
		counter_nxt = counter;
		unique case (state)
		INIT: begin
			if (is_multdiv) begin
			case (mult_type)
				MULT_MUL, MULT_MULW: begin
					counter_nxt = MULT_DELAY;
					state_nxt = DOING;
				end
				MULT_DIV, MULT_DIVU, MULT_REM, MULT_REMU, MULT_DIVW, MULT_DIVUW, MULT_REMW, MULT_REMUW: begin
					counter_nxt = DIV_DELAY;
					state_nxt = DOING;
				end
				default: begin

				end
			endcase
			end
		end
		DOING: begin
			counter_nxt = counter_nxt - 1;
			if (counter_nxt == 0) begin
				state_nxt = INIT;
			end
		end
		default: begin

		end
		endcase
	end : multicycle_counter
	assign mult_ok = state_nxt == INIT;
	
	// always_ff @(posedge clk) begin
		// if (~reset && state == INIT && is_multdiv && mult_type != MULT_MUL && mult_type != MULT_MULW)
			// $display("a %x, b %x", a, b);
	// end
	
endmodule



`endif
