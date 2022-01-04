`ifndef __JRSTACK_SV
`define __JRSTACK_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif

module jrstack
	import common::*;#(
	parameter LEN = 64,
	localparam type addr_t = logic[$clog2(LEN)-1:0]
) (
	input logic clk, reset,

	/* push if it is a `call` */
	input u32[FETCH_WIDTH-1:0] pc_i,
	input u1[FETCH_WIDTH-1:0] push_valid,

	/* pop */
	input u1[FETCH_WIDTH-1:0] pop_valid,
	output u32 pc_o
);
	addr_t t[1:0], t_nxt;
	localparam type counter_t = u8;
	localparam type entry_t = struct packed {
		u32 pc;
		counter_t counter;
	};

	u1 push, pop;
	u32 pc_push;

	always_comb begin
		push = '0;
		pop = '0;
		pc_push = 'x;
		for (int i = 0; i < FETCH_WIDTH; i++) begin
			unique if (push_valid[i]) begin
				push = 1'b1;
				pc_push = pc_i[i];
				break;
			end else if (pop_valid[i]) begin
				pop = 1'b1;
				break;
			end else begin
				
			end
		end
	end

	logic [$bits(entry_t)-1:0] stack [LEN-1:0];
	addr_t waddr;
	entry_t wdata;
	u1 wen;
	
	always_ff @(posedge clk) begin
		if (wen) begin
			stack[waddr] <= wdata;
			// `ASSERT(&wdata.counter);
		end
	end

	entry_t rdata;
	assign rdata = stack[t[1]];

	always_comb begin
		waddr = 'x;
		wdata = 'x;
		wen = '0;
		t_nxt = t[0];
		unique if (push) begin
			wdata.pc = pc_push;
			wen = '1;
			if (rdata.pc == pc_push) begin
				waddr = t[1];
				wdata.counter = rdata.counter + 1;
			end else begin
				waddr = t[0];
				wdata.counter = '0;
				t_nxt = t[0] + 1;
			end
		end else if (pop) begin
			if (|rdata.counter) begin
				wen = '1;
				waddr = t[1];
				wdata.pc = rdata.pc;
				wdata.counter = rdata.counter - 1;
			end else begin
				t_nxt = t[0] - 1;
			end
		end else begin
			
		end
	end
	
	
	always_ff @(posedge clk) begin
		if (reset) begin
			t[0] <= '0;
			t[1] <= '1;
		end else begin
			t[0] <= t_nxt;
			t[1] <= t_nxt - 1;
			// `ASSERT(&t[0]);
		end
	end
	
	assign pc_o = rdata.pc + 4;
endmodule


`endif
