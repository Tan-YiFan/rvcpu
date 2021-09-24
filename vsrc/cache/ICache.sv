`ifdef VERILATOR
`include "include/common.sv"
`include "ram/RAM_SinglePort.sv"
`endif
module ICache
	import common::*; (
	input logic clk, reset,
	input  ibus_req_t  ireq,
    output ibus_resp_t iresp,
    output cbus_req_t  creq,
    input  cbus_resp_t cresp
);
	localparam ALIGN_BITS = 3;
	localparam OFFSET_BITS = 7; // 2KB per line
	localparam CBUS_WIDTH = 3;
	localparam WORDS_PER_LINE = 2 ** (OFFSET_BITS - CBUS_WIDTH);
	localparam INDEX_BITS = 16 - OFFSET_BITS;
	localparam NUM_LINES = 2 ** INDEX_BITS;

	localparam type state_t = enum u1 {
		INIT = '0,
		FETCH
	};

	state_t state, state_nxt;
	u64 counter, counter_nxt;

	wire [INDEX_BITS-1:0] selected_idx = ireq.addr[OFFSET_BITS + INDEX_BITS -1 -: INDEX_BITS];

	u1 hit, valid_read;
	assign hit = valid_read;

	wire [OFFSET_BITS + INDEX_BITS - ALIGN_BITS - 1:0] ram_addr = state == INIT ?
	ireq.addr[OFFSET_BITS + INDEX_BITS - 1:ALIGN_BITS] :
	{ireq.addr[OFFSET_BITS + INDEX_BITS - 1 -: INDEX_BITS], counter[OFFSET_BITS - ALIGN_BITS - 1: 0]};
	u1 valid_wen, data_wen;
	always_comb begin
		{state_nxt, counter_nxt} = {state, counter};
		valid_wen = '0;
		data_wen = '0;
		unique case(state)
			INIT: begin
				if (ireq.valid) begin
					if (~hit) begin
						state_nxt = FETCH;
						counter_nxt = 1'b0;
					end
				end
			end
			FETCH: begin
				if (cresp.ready) begin
					counter_nxt = counter + 1;
					data_wen = 1'b1;
					if (cresp.last) begin
						state_nxt = INIT;
						counter_nxt = '0;
						valid_wen = '1;

					end
				end
			end
			default: begin
				
			end
		endcase
		
	end
	

	always_ff @(posedge clk) begin
		if (reset) begin
			{state, counter} <= '0;
		end else begin
			{state, counter} <= {state_nxt, counter_nxt};
		end
	end
	
	assign iresp.addr_ok = 1'b1;
	assign iresp.data_ok = state == INIT && hit;
	
	u64 selected_data;
	assign iresp.data = ireq.addr[2] ? selected_data[63:32] : selected_data[31:0];

	assign creq.valid = state == FETCH;
	assign creq.is_write = '0;
	assign creq.size = MSIZE8;
	assign creq.addr = {ireq.addr[63:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
	assign creq.strobe = '0;
	assign creq.data = '0;
	assign creq.len = MLEN16;
	assign creq.burst = AXI_BURST_INCR;

	RAM_SinglePort #(
		.ADDR_WIDTH(INDEX_BITS),
		.DATA_WIDTH(1),
		.BYTE_WIDTH(1),
		.MEM_TYPE(0),
		.READ_LATENCY(0)
	) valid_ram (
		.clk, .en(1'b1),
		.addr(selected_idx),
		.strobe(valid_wen),
		.wdata(1'b1),
		.rdata(valid_read)
	);
	RAM_SinglePort #(
		.ADDR_WIDTH(OFFSET_BITS + INDEX_BITS - ALIGN_BITS),
		.DATA_WIDTH(64),
		.BYTE_WIDTH(64),
		.MEM_TYPE(0),
		.READ_LATENCY(0)
	) data_ram (
		.clk,  .en(1'b1),
		.addr(ram_addr),
		.strobe(data_wen),
		.wdata(cresp.data),
		.rdata(selected_data)
	);

	always_ff @(posedge clk) begin
		// if (data_wen) $display("addr %x, wdata %x", ram_addr, cresp.data);
	end

	
endmodule