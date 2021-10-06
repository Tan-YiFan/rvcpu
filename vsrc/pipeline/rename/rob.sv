`ifndef __ROB_SV
`define __ROB_SV

`ifdef VERILATOR

`else

`endif

module rob
	import common::*;
	import rename_pkg::*;(
	input logic clk, reset,
	rename_intf.rob rename,
    commit_intf.rob commit,
	retire_intf.rob retire,
    hazard_intf.rob hazard,
    pcselect_intf.rob pcselect
);
	// h: read in commit; t: write in rename
	rob_ptr_t h[COMMIT_WIDTH-1:0], t[FETCH_WIDTH-1:0], h_nxt, t_nxt;
	always_ff @(posedge clk) begin
		if (reset) begin
			for (int i = 0; i < COMMIT_WIDTH; i++) begin
				h[i] <= i;
			end
			for (int i = 0; i < FETCH_WIDTH; i++) begin
				t[i] <= i;
			end
			
		end else begin
			for (int i = 0; i < COMMIT_WIDTH; i++) begin
				h[i] <= i + h_nxt;
			end
			for (int i = 0; i < FETCH_WIDTH; i++) begin
				t[i] <= i + t_nxt;
			end
		end
	end
	
	u1 [PREG_NUM-1:0] c, c_nxt;
	u1 full;
	function u1 is_full(rob_ptr_t h, t);
		return h[$bits(rob_ptr_t)-1] != t[$bits(rob_ptr_t)-1] && 
				preg_addr_t'(h) == preg_addr_t'(t);
	endfunction
	always_comb begin
		full = '0;
		for (int i = 0; i < COMMIT_WIDTH; i++) begin
			full |= is_full(t[i], h[0]);
		end
	end
	
	localparam type fetch_addr_t = logic [$clog2(FETCH_WIDTH)-1:0];
	localparam type bank_t = logic [$clog2(COMMIT_WIDTH)-1:0];
	localparam type bank_offset_t = logic[$clog2(PREG_NUM/COMMIT_WIDTH)-1:0];
	function bank_t bank(preg_addr_t p);
		return p[$clog2(COMMIT_WIDTH)-1:0];
	endfunction
	function bank_offset_t bank_offset(preg_addr_t p);
		return p[$clog2(PREG_NUM)-1:$clog2(COMMIT_WIDTH)];
	endfunction

	// rename stage
	rob_entry1_write_req w1[COMMIT_WIDTH-1:0];
	bank_offset_t ra1[COMMIT_WIDTH-1:0][R1_NUM-1:0];
	rob_entry1_t r1[COMMIT_WIDTH-1:0][R1_NUM-1:0];

	for (genvar i = 0; i < COMMIT_WIDTH; i++) begin : rob_entry1_gen
		for (genvar j = 0; j < R1_NUM; j++) begin
			RAM_SimpleDualPort #(
				.ADDR_WIDTH($clog2(PREG_NUM/COMMIT_WIDTH)),
				.DATA_WIDTH($bits(rob_entry1_t)),
				.BYTE_WIDTH($bits(rob_entry1_t)),
				.MEM_TYPE(0),
				.READ_LATENCY(0)
			) rob_entry1 (
				.clk, .en(1'b1),
				.raddr(ra1[i][j]),
				.waddr(w1[i].addr),
				.strobe(w1[i].valid),
				.wdata(w1[i].entry),
				.rdata(r1[i][j])
			);
		end
	end : rob_entry1_gen
	

	// commit2 stage
	rob_entry2_write_req w2[COMMIT_WIDTH-1:0];
	bank_offset_t ra2[COMMIT_WIDTH-1:0][R2_NUM-1:0];
	rob_entry2_t r2[COMMIT_WIDTH-1:0][R2_NUM-1:0];
	for (genvar i = 0; i < COMMIT_WIDTH; i++) begin : rob_entry2_gen
		for (genvar j = 0; j < R2_NUM; j++) begin
			RAM_SimpleDualPort #(
				.ADDR_WIDTH($clog2(PREG_NUM/COMMIT_WIDTH)),
				.DATA_WIDTH($bits(rob_entry2_t)),
				.BYTE_WIDTH($bits(rob_entry2_t)),
				.MEM_TYPE(0),
				.READ_LATENCY(0)
			) rob_entry2 (
				.clk, .en(1'b1),
				.raddr(ra2[i][j]),
				.waddr(w2[i].addr),
				.strobe(w2[i].valid),
				.wdata(w2[i].entry),
				.rdata(r2[i][j])
			);
		end
	end : rob_entry2_gen

	// rename
	for (genvar i = 0; i < COMMIT_WIDTH; i++) begin
		assign w1[i].valid = ~full && rename.instr[fetch_addr_t'(i - t[i])].valid;
		assign w1[i].addr = bank_offset(t[fetch_addr_t'(i - t[i])]);
		assign w1[i].entry = {
			{w1[i].addr, bank_t'(i)}, // preg
			rename.instr[fetch_addr_t'(i - t[i])].dst,
			rename.instr[fetch_addr_t'(i - t[i])].pc,
			rename.instr[fetch_addr_t'(i - t[i])].ctl
		};
	end

	for (genvar i = 0; i < FETCH_WIDTH; i++) begin
		assign rename.psrc[i] = t[i];
	end
	
	

	always_ff @(posedge clk) begin
		if (reset) begin
			c <= '0;
		end else begin
			c <= c_nxt;
		end
	end
	
	always_comb begin
		c_nxt = c;
		// rename stage, set c to 0
		t_nxt = t[0];
		if (~full) begin
			for (int i = 0; i < FETCH_WIDTH; i++) begin
				if (rename.instr[i].valid) begin
					for (int j = 0; j < PREG_NUM; j++) begin
						if (j == preg_addr_t'(t[i])) begin
							c_nxt[j] = '0;
						end
					end
					t_nxt = t[i] + 1;
				end
			end
		end
		// commit2 stage, set c to 1

	end


	
endmodule
`endif
