`ifndef __CBUSTOSRAM_SV
`define __CBUSTOSRAM_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif
module CBusToSRAM 
	import common::*;(
	input logic clk, reset,

	// CBus
	input cbus_req_t oreq,
	output cbus_resp_t oresp,

	// RAMHelper
	output u64 rIdx,
	input u64 rdata,
	output u64 wIdx,
	output u64 wdata,
	output u64 wmask,
	output logic wen,
	output logic en
);
	localparam type state_t = enum u2 {
		INIT = '0,
		DOING
	};

	state_t state, state_nxt;
	

	assign oresp.ready = 1'b1;
	assign oresp.last = state_nxt == INIT;
	// assign oresp.data = rdata;
	u128 cnter, cnter1;
	always_ff @(posedge clk) begin
		if (reset) {cnter, cnter1} <= '0;
		else begin
			cnter1 <= cnter1 + 1;
			if (cnter1 == 10000) begin
				cnter1 <= '0;
				cnter <= cnter + 1;
			end
		end
	end
	
	always_comb begin
		oresp.data = rdata;
		unique case(oreq.addr)
			64'h40600008: oresp.data = '0;
			64'h3800bff8: oresp.data = cnter;
			default: begin
				
			end
		endcase
	end
	

	u64 addr;
	u64 idx;
	assign idx = {38'b0, addr[28:3]};
	assign rIdx = idx;
	assign wIdx = idx;
	assign wdata = oreq.data;
	for (genvar i = 0; i < 8; i++) begin
		assign wmask[i * 8 + 7 -: 8] = {8{oreq.strobe[i]}};
	end
	assign wen = oreq.valid && oreq.is_write && oreq.addr[31:28] == 4'd8;
	assign en = 1'b1;

	u64 counter, counter_nxt;

	always_comb begin
		
		counter_nxt = counter;
		addr = oreq.addr;
		unique case(state)
			INIT: begin
				if (oreq.valid) begin
					unique case(oreq.burst)
						AXI_BURST_FIXED: begin
							
							counter_nxt = '0;
						end
						AXI_BURST_INCR: begin
							`ASSERT(oreq.size == MSIZE8);
							counter_nxt = 64'b1;
						end

						default: begin
							$error("Burst not supported.");
						end
					endcase
				end
			end
			DOING: begin
				counter_nxt = counter + 1;
				addr = oreq.addr + {counter[61:0], 3'b00};
			end

			default: begin
				
			end
		endcase
	end

	always_comb begin
		state_nxt = state;
		unique case(state)
			INIT: begin
				if (oreq.valid) begin
					unique case(oreq.burst)
						AXI_BURST_FIXED: begin
						end
						AXI_BURST_INCR: begin
							`ASSERT(oreq.size == MSIZE8);
							state_nxt = DOING;
						end

						default: begin
							$error("Burst not supported.");
						end
					endcase
				end
			end
			DOING: begin
				if (counter == u8'(oreq.len))
					state_nxt = INIT;
			end
			default: begin
				
			end
		endcase
	end
	

	always_ff @(posedge clk) begin
		if (reset) begin
			state <= INIT;
			counter <= '0;
		end else begin
			state <= state_nxt;
			counter <= counter_nxt;
			if (wen) $display("addr %x", addr[31:0]);
		end
	end
	
	

endmodule


`endif
