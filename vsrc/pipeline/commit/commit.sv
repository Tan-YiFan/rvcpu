`ifndef __COMMIT_SV
`define __COMMIT_SV

`ifdef VERILATOR
`include "include/interface.svh"
`else
// `include "interface.svh"
`endif

// module commit
// 	import common::*;(
// 	input logic clk, reset,
// 	creg_intf.commit creg,
	
// );

// endmodule

module fifo_mw1r
	import common::*;#(
	parameter QLEN = 16,
	parameter type TYPE = u64,
	parameter WNUM = 4,
	localparam type ptr_t = logic[$clog2(QLEN) : 0],
	localparam type addr_t = logic[$clog2(QLEN)-1 : 0]
)(
	input logic clk, reset,
	input logic[WNUM-1:0] valid,
	input TYPE [WNUM-1:0] write,
	output logic read_valid,
	output TYPE read
);
	addr_t h, t[WNUM-1:0], h_nxt, t_nxt;
	localparam type bank_t = logic [$clog2(WNUM)-1:0];
	localparam type bank_offset_t = logic[$clog2(QLEN)-1-$clog2(WNUM):0];
	function bank_t bank(addr_t p);
		return p[$clog2(WNUM)-1:0];
	endfunction
	function bank_offset_t bank_offset(addr_t p);
		return p[$clog2(QLEN)-1:$clog2(WNUM)];
	endfunction
	always_ff @(posedge clk) begin
		if (reset) begin
			h <= '0;
			t[0] <= '0;
			t[1] <= 1;
			t[2] <= 2;
			t[3] <= 3;
		end else begin
			h <= h_nxt;
			t[0] <= t_nxt;
			t[1] <= t_nxt + 1;
			t[2] <= t_nxt + 2;
			t[3] <= t_nxt + 3;
		end
	end
	TYPE data[WNUM-1:0][QLEN/WNUM-1:0];
	TYPE reads[WNUM-1:0];
	for (genvar i = 0; i < 4; i++) begin
		assign reads[i] = data[i][bank_offset(h)];
	end
	assign read = reads[bank(h)];
	assign read_valid = h != t[0];
	
	// assign read = data[bank(h)][bank_offset(h)];
	assign h_nxt = h + read_valid;
	logic [$clog2(WNUM)-1:0] wnum;
	TYPE [WNUM-1:0] wdata;
	logic [WNUM-1:0] wen;
	always_comb begin
		wnum = '0;
		wdata = '0;
		wen = '0;
		for (int i = 0; i < WNUM; i++) begin
			if (valid[i]) begin
				wdata[wnum] = write[i];
				wen[bank(t[wnum])] = 1'b1;
				wnum++;
			end
		end
	end
	assign t_nxt = t[0] + wnum;
	for (genvar i = 0; i < WNUM; i++) begin
		always_ff @(posedge clk) begin
			if (wen[i]) begin
				data[i][bank_offset(t[i])] <= wdata[i];
			end
		end
	end
		
	
endmodule



`endif
