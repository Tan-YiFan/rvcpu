`ifdef VERILATOR
`include "include/common.sv"
`include "ram/RAM_SinglePort.sv"
`endif

module DCache 
	import common::*;(
	input logic clk, reset,

	input  dbus_req_t  dreq,
    output dbus_resp_t dresp,
    output cbus_req_t  creq,
    input  cbus_resp_t cresp
);
	localparam ALIGN_BITS = 3;
	localparam OFFSET_BITS = 11; // 2KB per line
	localparam CBUS_WIDTH = 3;
	localparam WORDS_PER_LINE = 2 ** (OFFSET_BITS - CBUS_WIDTH);

	localparam INDEX_BITS = 8;
	localparam NUM_LINES = 2 ** INDEX_BITS;
	localparam TAG_WIDTH = 28 - OFFSET_BITS - INDEX_BITS;
	`ASSERT(TAG_WIDTH + INDEX_BITS + OFFSET_BITS >= 28);

	wire[TAG_WIDTH-1:0] tag = dreq.addr[INDEX_BITS + OFFSET_BITS + TAG_WIDTH - 1 -: TAG_WIDTH];
	wire[INDEX_BITS-1:0] index = dreq.addr[INDEX_BITS + OFFSET_BITS - 1 -: INDEX_BITS];
	localparam type line_meta_t = struct packed {
		u1 valid;
		// u1 dirty;
		logic [TAG_WIDTH-1:0] tag;
	};

	wire uncached = dreq.addr[31:28] != 4'd8 || dreq.addr[63:32] != 32'd0;

	localparam type state_t = enum u2 {
		INIT = '0,
		FETCH,
		WRITEBACK,
		UNCACHED
	};

	state_t state, state_nxt;
	u64 counter, counter_nxt;

	u1 hit;
	wire [INDEX_BITS-1:0] selected_idx = index;
	line_meta_t meta_read;

	wire [OFFSET_BITS + INDEX_BITS - 1:0] ram_addr = state == INIT ?
	{dreq.addr[OFFSET_BITS + INDEX_BITS - 1:ALIGN_BITS], 3'b00} : {index, counter[OFFSET_BITS - ALIGN_BITS - 1: 0], {ALIGN_BITS{1'b0}}};
	strobe_t data_wen;
	u1 meta_wen;
	line_meta_t meta_write;
	assign meta_write.valid = 1'b1;
	assign meta_write.tag = tag;
	assign hit = meta_read.valid && tag == meta_read.tag;
	wire dirty = tag != meta_read.tag && meta_read.valid;
	always_comb begin
		state_nxt = state;
		counter_nxt = counter;
		data_wen = '0;
		meta_wen = '0;
		unique case(state)
			INIT: begin
				if (dreq.valid) begin
					priority if (uncached) begin
						state_nxt = UNCACHED;
					end else if (hit) begin
						data_wen = dreq.strobe;
					end else if (dirty) begin
						state_nxt = WRITEBACK;
					end else begin
						state_nxt = FETCH;
					end
				end
			end
			FETCH: begin
				if (cresp.ready) begin
					counter_nxt = counter + 1;
					data_wen = '1;
					meta_wen = '1;
					if (cresp.last) begin
						// state_nxt = INIT;
						counter_nxt = '0;
						// meta_wen = '1;
						state_nxt = INIT;
					end
				end
			end
			WRITEBACK: begin
				if (cresp.ready) begin
					counter_nxt = counter + 1;
					if (cresp.last) begin
						counter_nxt = '0;
						state_nxt = FETCH;
					end
				end
			end
			UNCACHED: begin
				if (cresp.ready) begin
					state_nxt = INIT;
				end
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
		end
	end
	
	assign dresp.addr_ok = 1'b1;
	assign dresp.data_ok = (uncached && cresp.ready) || (~uncached && state == INIT && hit);
	
	u64 selected_data;
	assign dresp.data = uncached ? cresp.data : selected_data;

	

	assign creq.valid = state != INIT;
	assign creq.is_write = (state == UNCACHED && |dreq.strobe) || state == WRITEBACK;
	assign creq.size = state == UNCACHED ? dreq.size : MSIZE8;
	assign creq.addr = state == UNCACHED ? dreq.addr : 
	state == WRITEBACK ? {32'b0, 4'd8, meta_read.tag, index, 11'b0} : {dreq.addr[63:OFFSET_BITS], 11'b0};
	// assign creq.addr = dreq.addr;
	assign creq.strobe = state == UNCACHED ? dreq.strobe : '1;
	assign creq.data = state == UNCACHED ? dreq.data : selected_data;
	assign creq.len = state == UNCACHED ? MLEN1 : MLEN256;
	assign creq.burst = state == UNCACHED ? AXI_BURST_FIXED : AXI_BURST_INCR;

	RAM_SinglePort #(
		.ADDR_WIDTH(INDEX_BITS),
		.DATA_WIDTH(TAG_WIDTH + 1),
		.BYTE_WIDTH(TAG_WIDTH + 1),
		.READ_LATENCY(0),
		.MEM_TYPE(0)
	) meta_ram (
		.clk, .en(1'b1),
		.addr(selected_idx),
		.strobe(meta_wen),
		.wdata(meta_write),
		.rdata(meta_read)
	);

	RAM_SinglePort #(
		.ADDR_WIDTH(OFFSET_BITS + INDEX_BITS),
		.DATA_WIDTH(64),
		.BYTE_WIDTH(8),
		.MEM_TYPE(0),
		.READ_LATENCY(0)
	) data_ram (
		.clk,  .en(1'b1),
		.addr(ram_addr),
		.strobe(data_wen),
		.wdata(state == FETCH ? cresp.data : dreq.data),
		.rdata(selected_data)
	);

	always_ff @(posedge clk) begin
		// if (~reset && dreq.valid) $display("addr %x, state %d, counter_nxt %x", dreq.addr[31:0], state_nxt, counter_nxt);
		// if (~reset && dreq.valid && hit) $display("addr %x, data %x", dreq.addr, dresp.data);
		// if (~reset && state_nxt == FETCH && data_wen) $display("ram_addr %x, wdata %x", ram_addr, cresp.data);
		// if (~reset && state == UNCACHED) $display("%x, strobe %x, valid %x, ready %x, state_nxt %x", creq.addr, creq.is_write, creq.valid, cresp.ready, state_nxt);
		// if (dreq.addr == 64'h40600004) $display("oreq.addr %x, cresp.ready %x, state_nxt %x", creq.addr, cresp.ready, state_nxt);
		// if (dreq.valid && dreq.addr == 64'h800059a0) $display ("%x, strobe %x", dreq.data, dreq.strobe);
		// if (dreq.valid && |dreq.strobe && ~uncached && dresp.data_ok) $display ("addr %x, data %x, strobe %x", dreq.addr[31:0], dreq.data, dreq.strobe);
		// if (state == WRITEBACK) $display("ram_addr %x, selected_data %x. creq.data %x", ram_addr, selected_data, creq.data);
	end
	
	// check if written
	// always_ff @(posedge clk) begin
	// 	if (dreq.valid && |dreq.strobe && dresp.data_ok) begin
	// 		#1 `ASSERT(data_ram.mem[dreq.addr[21:3]])
	// 	end
	// end
	

endmodule
