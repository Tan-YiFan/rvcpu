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
    pcselect_intf.rob pcselect,
	ready_intf.rob ready
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
		assign w1[i].valid = ~full && rename.instr[fetch_addr_t'(i - fetch_addr_t'(t[0]))].valid;
		assign w1[i].addr = bank_offset(t[fetch_addr_t'(i - fetch_addr_t'(t[0]))]);
		assign w1[i].entry.preg = {bank_offset(t[fetch_addr_t'(i - fetch_addr_t'(t[0]))]), bank_t'(i)};
		assign w1[i].entry.creg = rename.instr[fetch_addr_t'(i - fetch_addr_t'(t[0]))].dst;
		assign w1[i].entry.pc = rename.instr[fetch_addr_t'(i - fetch_addr_t'(t[0]))].pc;
		assign w1[i].entry.ctl = rename.instr[fetch_addr_t'(i - fetch_addr_t'(t[0]))].ctl;
	end

	for (genvar i = 0; i < FETCH_WIDTH; i++) begin
		assign rename.psrc[i] = t[i];
	end
	
	// commit
	for (genvar i = 0; i < COMMIT_WIDTH; i++) begin
		assign w2[i].valid = commit.valid[i];
		assign w2[i].addr = bank_offset(commit.instr[i].dst);
		assign w2[i].entry = commit.instr[i].data;
	end
	// retire
	u1 v_retire[COMMIT_WIDTH-1:0]/*verilator split_var*/;
	assign v_retire[0] = c[preg_addr_t'(h[0])] && h[0] != t[0];
	for (genvar i = 1; i < COMMIT_WIDTH; i++) begin
		assign v_retire[i] = v_retire[i - 1] && c[preg_addr_t'(h[i])] && h[i] != t[0];
	end
	always_comb begin
		for (int i = 0; i < COMMIT_WIDTH; i++) begin
			for (int j = 0; j < R1_NUM; j++) begin
				ra1[i][j] = 'x;
			end
		end
		for (int i = 0; i < COMMIT_WIDTH; i++) begin
			for (int j = 0; j < R2_NUM; j++) begin
				ra2[i][j] = 'x;
			end
		end
		for (int i = 0; i < COMMIT_WIDTH; i++) begin
			ra1[bank(h[i])][i] = bank_offset(h[i]);
			ra2[bank(h[i])][i] = bank_offset(h[i]);
		end
	end
	
	for (genvar i = 0; i < COMMIT_WIDTH; i++) begin
		assign retire.retire[i].valid = v_retire[i];
		assign retire.retire[i].data = r2[bank(h[i])][i].data;
		assign retire.retire[i].ctl = r1[bank(h[i])][i].ctl;
		assign retire.retire[i].dst = r1[bank(h[i])][i].creg;
		assign retire.retire[i].preg = h[i];
		assign retire.retire[i].pc = r1[bank(h[i])][i].pc;
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
		h_nxt = h[0];
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
		for (int i = 0; i < FETCH_WIDTH; i++) begin
			if (commit.valid[i]) begin
				for (int j = 0; j < PREG_NUM; j++) begin
					if (j == preg_addr_t'(commit.instr[i].dst)) begin
						c_nxt[j] = 1'b1;
					end
				end
			end
		end
		// retire
		for (int i = 0; i < COMMIT_WIDTH; i++) begin
			if (retire.retire[i].valid) begin
				h_nxt = h[i] + 1;
			end
		end
		
	end

	always_ff @(posedge clk) begin
		// if (retire.retire[1].valid) begin
			// $display("%x", retire.retire[1].pc);
		// end
		// if (commit.valid[0]) begin
		// 	$display("%x", commit.instr[0].dst);
		// end
		// if (c[0]) begin
		// 	$display("%x, %x", h[0], t[0]);
		// end
	end
	
	for (genvar i = 0; i < FETCH_WIDTH; i++) begin
		assign ready.v1[i] = c[ready.psrc1[i]];
		assign ready.v2[i] = c[ready.psrc2[i]];
	end
	
endmodule
`endif
