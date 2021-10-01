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
	localparam READ_BITS = 2;
	localparam OFFSET_BITS = COMMON_OFFSET_BITS; // 2KB per line
	localparam CBUS_WIDTH = 3;
	localparam WORDS_PER_LINE = 2 ** (OFFSET_BITS - CBUS_WIDTH);
	localparam INDEX_BITS = ICACHE_BITS - OFFSET_BITS;
	localparam GROUP_BITS = 2;
	localparam NUM_LINES = 2 ** INDEX_BITS;
	localparam TAG_WIDTH = 28 - OFFSET_BITS - INDEX_BITS;
	localparam META_WIDTH = TAG_WIDTH + 1;
	localparam BINFO_WIDTH = PC_WIDTH + 2;

	localparam type state_t = enum u1 {
		INIT = '0,
		FETCH
	};

	localparam type binfo_t = struct packed {
		u1 branch;
		u1 call;
		u1 ret;
		pc_t pc;
	};

	state_t state, state_nxt;
	u64 counter, counter_nxt;

	// wire [INDEX_BITS-1:0] selected_idx = ireq.addr[OFFSET_BITS + INDEX_BITS -1 -: INDEX_BITS];
	wire [TAG_WIDTH-1:0] tag = ireq.addr[27-:TAG_WIDTH];
	logic [TAG_WIDTH-1:0] tag_read;

	u1 hit, valid_read;
	assign hit = valid_read && tag_read == tag;

	// wire [OFFSET_BITS + INDEX_BITS - ALIGN_BITS - 1:0] ram_addr = state == INIT ?
	// ireq.addr[OFFSET_BITS + INDEX_BITS - 1:ALIGN_BITS] :
	// {ireq.addr[OFFSET_BITS + INDEX_BITS - 1 -: INDEX_BITS], counter[OFFSET_BITS - ALIGN_BITS - 1: 0]};
	u1 valid_wen, data_wen;


	if (FETCH_STAGE == 1) begin
		wire [INDEX_BITS - 1:0] meta_addr = ireq.addr[OFFSET_BITS + INDEX_BITS -1 -: INDEX_BITS];
		wire meta_strobe = valid_wen;
		wire [META_WIDTH - 1:0] meta_write = {1'b1, tag};
		wire [META_WIDTH - 1:0] meta_read = {valid_read, tag_read};
		
		wire [INDEX_BITS + OFFSET_BITS - READ_BITS - GROUP_BITS - 1:0][2 ** GROUP_BITS -1:0] data_addr, binfo_addr;
		wire [INDEX_BITS + OFFSET_BITS - READ_BITS - GROUP_BITS - 1:0]  data_strobe, binfo_strobe;
		wire [INDEX_BITS + OFFSET_BITS - READ_BITS - GROUP_BITS - 1:0][31:0] data_write, data_read;
		binfo_t [INDEX_BITS + OFFSET_BITS - READ_BITS - GROUP_BITS - 1:0] binfo_write, binfo_read;
		pc_t [INDEX_BITS + OFFSET_BITS - READ_BITS - GROUP_BITS - 1:0] this_pc;
		for (genvar i = 0; i < 2 ** GROUP_BITS; i++) begin
			assign data_addr[i] = state == INIT ?
			ireq.addr[OFFSET_BITS + INDEX_BITS - 1:ALIGN_BITS + GROUP_BITS - 1] :
			{ireq.addr[OFFSET_BITS + INDEX_BITS - 1 -: INDEX_BITS], counter[OFFSET_BITS - ALIGN_BITS - 1: 1]};
			assign data_strobe[i] = data_wen && counter[0] == i[1];
			assign data_write[i] = i[0] ? cresp.data[63:32] : cresp.data[31:0];
			assign binfo_addr[i] = data_addr[i];
			assign binfo_strobe[i] = data_strobe[i];
			assign this_pc[i] = {
				32'b0,
				4'd8,
				tag,
				{ireq.addr[OFFSET_BITS + INDEX_BITS - 1 -: INDEX_BITS], counter[OFFSET_BITS - ALIGN_BITS - 1: 1]},
				i[1:0],
				2'b00
			};

			predecode pd(
				.raw_instr(data_write[i]),
				.this_pc(this_pc[i]),
				.branch(binfo_write[i].branch),
				.call(binfo_write[i].call),
				.ret(binfo_write[i].ret),
				.target_pc(binfo_write[i].pc)
			);
			wire [1:0] off = ~i[1:0];

			/* verilator lint_off CMPCONST */
			assign iresp.data[i].valid = ireq.addr[3:2] <= off;
			/* verilator lint_on CMPCONST */
			assign iresp.data[i].raw_instr = data_read[i];
			assign iresp.data[i].branch = binfo_read[i].branch;
			assign iresp.data[i].call = binfo_read[i].call;
			assign iresp.data[i].ret = binfo_read[i].ret;
			assign iresp.data[i].pc_nxt = binfo_read[i].pc;
		end
		RAM_SinglePort #(
			.ADDR_WIDTH(INDEX_BITS),
			.DATA_WIDTH(META_WIDTH),
			.BYTE_WIDTH(META_WIDTH),
			.MEM_TYPE(1),
			.READ_LATENCY(0)
		) meta_ram (
			.clk,  .en(1'b1),
			.addr(meta_addr),
			.strobe(meta_strobe),
			.wdata(meta_write),
			.rdata(meta_read)
		);

		for (genvar i = 0; i < 2 ** GROUP_BITS; i++) begin
			RAM_SinglePort #(
				.ADDR_WIDTH(INDEX_BITS + OFFSET_BITS - READ_BITS - GROUP_BITS + 1),
				.DATA_WIDTH(32),
				.BYTE_WIDTH(32),
				.MEM_TYPE(1),
				.READ_LATENCY(0)
			) data_ram (
				.clk,  .en(1'b1),
				.addr(data_addr[i]),
				.strobe(data_strobe[i]),
				.wdata(data_write[i]),
				.rdata(data_read[i])
			);

			RAM_SinglePort #(
				.ADDR_WIDTH(INDEX_BITS + OFFSET_BITS - READ_BITS - GROUP_BITS + 1),
				.DATA_WIDTH(BINFO_WIDTH),
				.BYTE_WIDTH(BINFO_WIDTH),
				.MEM_TYPE(1),
				.READ_LATENCY(0)
			) meta_ram (
				.clk,  .en(1'b1),
				.addr(binfo_addr[i]),
				.strobe(binfo_strobe[i]),
				.wdata(binfo_write[i]),
				.rdata(binfo_read[i])
			);
		end
		
		
	end else begin
		
	end
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
	
	// assign iresp.data = ireq.addr[2] ? selected_data[63:32] : selected_data[31:0];

	assign creq.valid = state == FETCH;
	assign creq.is_write = '0;
	assign creq.size = MSIZE8;
	assign creq.addr = {ireq.addr[63:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
	assign creq.strobe = '0;
	assign creq.data = '0;
	assign creq.len = AXI_BURST_LEN;
	assign creq.burst = AXI_BURST_INCR;

	always_ff @(posedge clk) begin
		// if (data_wen) $display("addr %x, wdata %x", ram_addr, cresp.data);
	end

	
endmodule

module predecode 
	import common::*;(
	input logic [31:0] raw_instr,
	input pc_t this_pc,
	output logic branch, call, ret,
	output pc_t target_pc
);
	wire [6:0] op = raw_instr[6:0];
	wire [4:0] rd = raw_instr[11:7];
	wire [4:0] rs1 = raw_instr[19:15];
	assign branch = op == 7'b1100011;
	assign call = (op == 7'b1101111 || op == 7'b1100111) && rd != 5'b0;
	assign ret = (op == 7'b1100111) && rs1 == 5'd1;
	always_comb begin
		
	end
	
endmodule
