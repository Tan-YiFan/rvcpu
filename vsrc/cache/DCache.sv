`ifdef VERILATOR
`include "include/common.sv"
`include "ram/RAM_SinglePort.sv"
`include "ram/RAM_SimpleDualPort.sv"
`include "ram/RAM_TrueDualPort.sv"

`endif

module DCache 
	import common::*;(
	input logic clk, reset,

	input  dbus_req_t [1:0] dreq,
    output dbus_resp_t [1:0] dresp,
    output cbus_req_t  creq,
    input  cbus_resp_t cresp
);
	localparam ALIGN_BITS = 3;
	localparam OFFSET_BITS = COMMON_OFFSET_BITS; // 2KB per line
	localparam CBUS_WIDTH = 3;
	localparam WORDS_PER_LINE = 2 ** (OFFSET_BITS - CBUS_WIDTH);

	localparam INDEX_BITS = DCACHE_BITS - OFFSET_BITS;
	localparam NUM_LINES = 2 ** INDEX_BITS;
	localparam TAG_WIDTH = 28 - OFFSET_BITS - INDEX_BITS;
	`ASSERT(TAG_WIDTH + INDEX_BITS + OFFSET_BITS >= 28);

	u1 miss_id;

	wire [1:0][TAG_WIDTH-1:0] tag;
	for (genvar i = 0; i < 2; i++) begin
		assign tag[i] = dreq[i].addr[INDEX_BITS + OFFSET_BITS + TAG_WIDTH - 1 -: TAG_WIDTH];
	end
	 
	wire [1:0][INDEX_BITS-1:0] index;
	for (genvar i = 0; i < 2; i++) begin
		assign index[i] = dreq[i].addr[INDEX_BITS + OFFSET_BITS - 1 -: INDEX_BITS];
	end
	 
	localparam type line_meta_t = struct packed {
		u1 valid;
		// u1 dirty;
		logic [TAG_WIDTH-1:0] tag;
	};

	localparam type state_t = enum u2 {
		INIT = '0,
		FETCH,
		WRITEBACK,
		UNCACHED
	};

	state_t state, state_nxt;
	u64 counter, counter_nxt;

	u1[1:0] hit;
	wire [1:0][INDEX_BITS-1:0] selected_idx = index;
	line_meta_t[1:0] meta_read;

	logic [OFFSET_BITS-ALIGN_BITS-1:0] buffer_counter, buffer_counter_nxt, buffer_counter_delayed, buffer_counter_delayed1;

	wire [1:0][OFFSET_BITS + INDEX_BITS - ALIGN_BITS - 1:0] ram_addr;
	for (genvar i = 0; i < 2; i++) begin
		assign ram_addr[i] = state == INIT ?
		{dreq[i].addr[OFFSET_BITS + INDEX_BITS - 1:ALIGN_BITS]} :
		state == WRITEBACK ? {index[i], buffer_counter[OFFSET_BITS - ALIGN_BITS - 1: 0]} :
		{index[i], counter[OFFSET_BITS - ALIGN_BITS - 1: 0]};
	end
	
	strobe_t data_wen[1:0];
	u1 meta_wen;
	line_meta_t meta_write;
	assign meta_write.valid = 1'b1;
	assign meta_write.tag = tag[miss_id];

	for (genvar i = 0; i < 2; i++) begin
		assign hit[i] = ~dreq[i].valid || (meta_read[i].valid && tag[i] == meta_read[i].tag);
	end
	assign miss_id = ~hit[1];
	
	wire [1:0] dirty;
	for (genvar i = 0; i < 2; i++) begin
		assign dirty[i] = meta_read[i].valid;
	end
	
	u64 buffer_read;
	
	always_comb begin
		state_nxt = state;
		counter_nxt = counter;
		data_wen[0] = '0;
		data_wen[1] = '0;
		meta_wen = '0;
		unique case(state)
			INIT: begin
				if (dreq[0].valid | dreq[1].valid) begin
					priority if (&hit) begin
						data_wen[0] = dreq[0].strobe;
						data_wen[1] = dreq[1].strobe;
					end else if (dirty[miss_id]) begin
						state_nxt = WRITEBACK;
					end else begin
						state_nxt = FETCH;
					end
				end
			end
			FETCH: begin
				if (cresp.ready) begin
					counter_nxt = counter + 1;
					data_wen[miss_id] = '1;
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

	always_comb begin
		buffer_counter_nxt = '0;
		unique case(state)
			WRITEBACK: begin
				buffer_counter_nxt = buffer_counter + 1;
			end
			default: begin
				
			end
		endcase
	end

	always_ff @(posedge clk) begin
		if (reset) begin
			buffer_counter <= '0;
			buffer_counter_delayed <= '0;
			buffer_counter_delayed1 <= '0;
		end else begin
			buffer_counter <= buffer_counter_nxt;
			buffer_counter_delayed1 <= buffer_counter;
			buffer_counter_delayed <= buffer_counter_delayed1;
		end
	end
	
	
	for (genvar i = 0; i < 2; i++) begin
		assign dresp[i].addr_ok = 1'b1;
		assign dresp[i].data_ok = state == INIT && &hit;
	end
	

	
	u64[1:0] selected_data;
	// assign dresp.data = uncached && dreq.valid ? cresp.data : selected_data;

	

	assign creq.valid = state != INIT;
	assign creq.is_write = state == WRITEBACK;
	assign creq.size = MSIZE8;
	assign creq.addr = state == WRITEBACK ? {32'b0, 4'd8, meta_read[miss_id].tag, index, {OFFSET_BITS{1'b0}}} : {dreq[miss_id].addr[63:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
	// assign creq.addr = dreq.addr;
	assign creq.strobe = '1;
	assign creq.data = buffer_read;
	assign creq.len = state == UNCACHED ? MLEN1 : AXI_BURST_LEN;
	assign creq.burst = state == UNCACHED ? AXI_BURST_FIXED : AXI_BURST_INCR;

	// RAM_SinglePort #(
	// 	.ADDR_WIDTH(INDEX_BITS),
	// 	.DATA_WIDTH(TAG_WIDTH + 1),
	// 	.BYTE_WIDTH(TAG_WIDTH + 1),
	// 	.READ_LATENCY(0),
	// 	.MEM_TYPE(0)
	// ) meta_ram (
	// 	.clk, .en(1'b1),
	// 	.addr(selected_idx),
	// 	.strobe(meta_wen),
	// 	.wdata(meta_write),
	// 	.rdata(meta_read)
	// );

	logic [INDEX_BITS-1:0] selected_idx_delayed;
	always_ff @(posedge clk) begin
		selected_idx_delayed <= selected_idx[miss_id];
	end
	

	LUTRAM_DualPort #(
		.ADDR_WIDTH(INDEX_BITS),
		.DATA_WIDTH(TAG_WIDTH + 1),
		.BYTE_WIDTH(TAG_WIDTH + 1),
		.READ_LATENCY(0)
	) meta_ram (
		.clk(clk),
		.en_1(1'b1),
		.en_2(1'b1),

		.addr_1(state == INIT ? selected_idx[0] : selected_idx_delayed),
		.addr_2(selected_idx[1]),
		.strobe(meta_wen),
		.wdata(meta_write),
		.rdata_1(meta_read[0]),
		.rdata_2(meta_read[1])
	);

	// RAM_SinglePort #(
	// 	.ADDR_WIDTH(OFFSET_BITS + INDEX_BITS - ALIGN_BITS),
	// 	.DATA_WIDTH(64),
	// 	.BYTE_WIDTH(8),
	// 	.MEM_TYPE(3),
	// 	.READ_LATENCY(1)
	// ) data_ram (
	// 	.clk,  .en(1'b1),
	// 	.addr(ram_addr),
	// 	.strobe(data_wen),
	// 	.wdata(state == FETCH ? cresp.data : dreq.data),
	// 	.rdata(selected_data)
	// );

	RAM_TrueDualPort #(
		.ADDR_WIDTH(OFFSET_BITS + INDEX_BITS - ALIGN_BITS),
		.DATA_WIDTH(64),
		.BYTE_WIDTH(8),
		.MEM_TYPE(0),
		.READ_LATENCY(2)
	) data_ram (
		.clk, .en_1(1'b1), .en_2(1'b1),
		.addr_1(ram_addr[0]),
		.addr_2(ram_addr[1]),
		.strobe_1(data_wen[0]),
		.strobe_2(data_wen[1]),
		.wdata_1(state == FETCH ? cresp.data : dreq[0].data),
		.wdata_2(state == FETCH ? cresp.data : dreq[1].data),
		.rdata_1(selected_data[0]),
		.rdata_2(selected_data[1])
	);

	RAM_SimpleDualPort #(
		.ADDR_WIDTH(OFFSET_BITS - ALIGN_BITS),
		.DATA_WIDTH(64),
		.BYTE_WIDTH(64),
		.MEM_TYPE(0),
		.READ_LATENCY(0)
	) wb_buffer (
		.clk, .en(1'b1),
		.raddr({/* index,  */counter[OFFSET_BITS - ALIGN_BITS - 1: 0]}),
		.waddr(buffer_counter_delayed),
		.strobe(state == WRITEBACK),
		.wdata(selected_data[miss_id]),
		.rdata(buffer_read)
	);

	for (genvar i = 0; i < 2; i++) begin
		assign dresp[i].data = selected_data[i];
	end
	
	// assign dresp.data = selected_data;
	
	always_ff @(posedge clk) begin
		// if (~reset && dreq.valid) $display("addr %x, state %d, counter_nxt %x", dreq.addr[31:0], state_nxt, counter_nxt);
		// if (~reset && dreq.valid && hit) $display("addr %x, data %x %x", dreq.addr, dreq.data, data_delay);
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
	for (genvar i = 0; i < 2; i++) begin
		always_ff @(posedge clk) begin
			if (state == INIT && dreq[i].valid) $display("%x", dreq[i].addr);
		end
		
	end
	

endmodule
