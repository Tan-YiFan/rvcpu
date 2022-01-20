`ifndef __ROB_SV
`define __ROB_SV

`ifdef VERILATOR

`else

`endif

module rob
	import common::*;
	import rename_pkg::*;
	import issue_pkg::*;(
	input logic clk, reset,
	rename_intf.rob rename,
    commit_intf.rob commit,
	retire_intf.rob retire,
    hazard_intf.rob hazard,
    pcselect_intf.rob pcselect,
	ready_intf.rob ready,
	wake_intf.rob wake,
	source_intf.rob source,
	wbuffer_intf.rob wbuffer,
	bp_intf.rob bp,

	input dbus_resp_t[WMEM_WIDTH-1:0] dresp,
	output cbus_req_t ureq,
	input cbus_resp_t uresp,
	input d_data_ok
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
		assign w2[i].valid = commit.valid[i] && commit.instr[i].valid;
		assign w2[i].addr = bank_offset(commit.instr[i].dst);
		assign w2[i].entry = {commit.instr[i].extra, commit.instr[i].data};
		assign wake.wake[i].valid = commit.valid[i] && commit.instr[i].valid;
		assign wake.wake[i].id = commit.instr[i].dst;
	end
	// retire
	u1 [COMMIT_WIDTH-1:0]v_retire;
	u1 [COMMIT_WIDTH-1:0]validR;

	u2 wnum;
	u2 wmem_id[1:0];

	always_comb begin
		wnum = '0;
		wmem_id[0] = 'x;
		wmem_id[1] = 'x;
		for (int i = 0; i < 4; i++) begin
			if (~c[preg_addr_t'(h[i])]) break;
			if (~r2[bank(h[i])][i].data.mem.extra.uncached
			&& r1[bank(h[i])][i].ctl.memwrite) begin
				wmem_id[wnum] = i;
				wnum++;
				// if (r1[bank(h[i])][i].pc == 32'h80002664) $display("%x", wnum, i);
				if (wnum == 2) break;
			end
		end
		
	end
	for (genvar i = 0; i < 4; i++) begin
		always_ff @(posedge clk) begin
			// if (r1[bank(h[i])][i].pc == 32'h80002664) $display("%x", r2[bank(h[i])][i].data.mem.extra.uncached);
		end
		
	end
	
	
	always_comb begin
		v_retire = '0;

		/* Complete */
		v_retire[0] = c[preg_addr_t'(h[0])]
					&& h[0] != t[0]
					&& ~(r1[bank(h[0])][0].ctl.entry_type == ENTRY_MEM && r2[bank(h[0])][0].data.mem.extra.uncached && ~uresp.last)
					&& d_data_ok
					;
		if (ureq.valid) begin
			v_retire[0] = v_retire[0] && uresp.ready;
		end else begin
			v_retire[0] = v_retire[0] && dresp[0].data_ok && dresp[1].data_ok;
		end
		validR = '0;

		/* Branch Predict Failed */
		if (r1[bank(h[0])][0].ctl.entry_type == ENTRY_BR &&
				r2[bank(h[0])][0].data.branch.extra.branch.pd_fail) begin
					validR[0] = v_retire[0];
		end
		for (int i = 1; i < COMMIT_WIDTH; i++) begin
			v_retire[i] = v_retire[i - 1] 
			&& c[preg_addr_t'(h[i])] 
			&& h[i] != t[0] 
			&& ~validR[i-1]
			&& ~(r1[bank(h[0])][0].ctl.entry_type == ENTRY_MEM && r2[bank(h[0])][0].data.mem.extra.uncached)
			&& ~(r1[bank(h[i])][i].ctl.entry_type == ENTRY_MEM && r2[bank(h[i])][i].data.mem.extra.uncached)
			&& ~ureq.valid

			&& ~(r1[bank(h[i])][i].ctl.memwrite && wnum == 2 && wmem_id[1] != i)
			;
			if (r1[bank(h[i])][i].ctl.entry_type == ENTRY_BR &&
				r2[bank(h[i])][i].data.branch.extra.branch.pd_fail) begin
					validR[i] = v_retire[i];
			end
		end
		
	end
	
	// assign v_retire[0] = c[preg_addr_t'(h[0])] && h[0] != t[0];
	// for (genvar i = 1; i < COMMIT_WIDTH; i++) begin
	// 	assign v_retire[i] = v_retire[i - 1] && c[preg_addr_t'(h[i])] && h[i] != t[0] && ~|validR[i-1:0];
	// end
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
		for (int i = 0; i < AREG_READ_PORTS; i++) begin
			ra2[bank(source.psrc1[i])][COMMIT_WIDTH + i] = bank_offset(source.psrc1[i]);
		end
		for (int i = 0; i < AREG_READ_PORTS; i++) begin
			ra2[bank(source.psrc2[i])][COMMIT_WIDTH + AREG_READ_PORTS + i] = bank_offset(source.psrc2[i]);
		end
	end
	// always_comb begin
	// 	validR = '0;
	// 	for (int i = 0; i < COMMIT_WIDTH; i++) begin
	// 		if (~retire.retire[i].valid) begin
	// 			break;
	// 		end
	// 		if (r1[bank(h[i])][i].ctl.entry_type == ENTRY_BR &&
	// 			r2[bank(h[i])][i].data.branch.extra.branch.pd_fail) begin
	// 				validR[i] = 1'b1;
	// 		end
	// 	end
	// end

	u64 rd_uncached;
	readdata readdata(
        ._rd(uresp.data),
        .msize(r1[bank(h[0])][0].ctl.msize),
        .addr(ureq.addr[2:0]),
		.mem_unsigned(r1[bank(h[0])][0].ctl.mem_unsigned),
        .rd(rd_uncached)
    );
	
	
	for (genvar i = 0; i < COMMIT_WIDTH; i++) begin
		assign retire.retire[i].valid = v_retire[i];
		assign retire.retire[i].data = ureq.valid ? rd_uncached : r2[bank(h[i])][i].data;
		assign retire.retire[i].ctl = r1[bank(h[i])][i].ctl;
		assign retire.retire[i].dst = r1[bank(h[i])][i].creg;
		assign retire.retire[i].preg = h[i];
		assign retire.retire[i].pc = r1[bank(h[i])][i].pc;
		assign retire.retire[i].uncached = ureq.valid;
		assign pcselect.pcbranchR[i] = r2[bank(h[i])][i].data.branch.extra.branch.correct_pc;
		assign pcselect.validR[i] = validR[i];
		
		
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
		// $display("%x %x %x %x", c[0], c[1], c[2], c[3]);
	end
	
	for (genvar i = 0; i < FETCH_WIDTH; i++) begin
		assign ready.v1[i] = c[ready.psrc1[i]];
		assign ready.v2[i] = c[ready.psrc2[i]];
	end

	for (genvar i = 0; i < AREG_READ_PORTS; i++) begin
		assign source.prf1[i] = r2[bank(source.psrc1[i])][COMMIT_WIDTH + i];
		assign source.prf2[i] = r2[bank(source.psrc2[i])][COMMIT_WIDTH + AREG_READ_PORTS + i];
	end
	
	assign hazard.pd_fail = |validR;
	assign hazard.rob_full = full;

	assign ureq.valid =
	c[preg_addr_t'(h[0])]
	&& r1[bank(h[0])][0].ctl.entry_type == ENTRY_MEM 
	&& r2[bank(h[0])][0].data.mem.extra.uncached;
	assign ureq.is_write = r1[bank(h[0])][0].ctl.memwrite;
	assign ureq.size = r2[bank(h[0])][0].data.mem.extra.msize;
	assign ureq.addr = r2[bank(h[0])][0].data.mem.extra.addr;
	assign ureq.strobe = r2[bank(h[0])][0].data.mem.extra.strobe;
	assign ureq.data = r2[bank(h[0])][0].data.mem.data;
	assign ureq.len = MLEN1;
	assign ureq.burst = AXI_BURST_FIXED;

	// for (genvar i = 0; i < 2; i++) begin
	// 	assign wbuffer.creq[i].valid = (wnum > i) && c[preg_addr_t'(h[wmem_id[i]])];
	// end
	assign wbuffer.creq[0].valid = (wnum != 0) && c[preg_addr_t'(h[wmem_id[0]])];
	assign wbuffer.creq[1].valid = (wnum == 2) && c[preg_addr_t'(h[wmem_id[1]])];
	always_ff @(posedge clk) begin
		// if (wbuffer.creq[0].valid) $display("%x", retire.retire[wmem_id[0]].pc);
	end
	always_ff @(posedge clk) begin
		// if (ureq.valid) $display("1");
	end
	
	
endmodule
`endif
