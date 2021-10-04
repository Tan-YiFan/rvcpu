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
);
	rob_ptr_t h[COMMIT_WIDTH-1:0], t[COMMIT_WIDTH-1:0], h_nxt, t_nxt;
	always_ff @(posedge clk) begin
		if (reset) begin
			h[0] <= '0;
			h[1] <= 1;
			h[2] <= 2;
			h[3] <= 3;
			t[0] <= '0;
			t[1] <= 1;
			t[2] <= 2;
			t[3] <= 3;
		end else begin
			h[0] <= h_nxt;
			h[1] <= h_nxt + 1;
			h[2] <= h_nxt + 2;
			h[3] <= h_nxt + 3;
			t[0] <= t_nxt;
			t[1] <= t_nxt + 1;
			t[2] <= t_nxt + 2;
			t[3] <= t_nxt + 3;
		end
	end
	

endmodule

	u1 [PREG_NUM-1:0]complete;
	u1 full;
	localparam type bank_t = logic [$clog2(COMMIT_WIDTH)-1:0];
	localparam type bank_offset_t = logic[$clog2(PREG_NUM/COMMIT_WIDTH)-1:0];
	function bank_t bank(preg_addr_t p);
		return p[$clog2(WNUM)-1:0];
	endfunction
	function bank_offset_t bank_offset(preg_addr_t p);
		return p[$clog2(QLEN)-1:$clog2(WNUM)];
	endfunction
	rob_entry1_t entry1[$clog2(COMMIT_WIDTH)-1:0][$clog2(PREG_NUM/COMMIT_WIDTH)-1:0];
	rob_entry2_t entry2[$clog2(COMMIT_WIDTH)-1:0][$clog2(PREG_NUM/COMMIT_WIDTH)-1:0];


`endif
