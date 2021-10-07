`ifndef __COMMIT_SV
`define __COMMIT_SV

`ifdef VERILATOR
`include "include/interface.svh"
`else
`include "interface.svh"
`endif

module commit
	import common::*;
	import execute_pkg::*;
	import commit_pkg::*;(
	input logic clk, reset,
	creg_intf.commit creg,
	commit_intf.commit self
);
	execute_data_t dataE;

	localparam WNUM = 8;
	u1 [COMMIT_WIDTH-1:0][WNUM-1:0] valid;
	commit_instr_t [COMMIT_WIDTH-1:0][WNUM-1:0] write;
	always_comb begin
		valid = '0;
		write = 'x;
		// alu
		for (int i = 0; i < 4; i++) begin
			if (dataE.alu_commit[i].valid) begin
				// `ASSERT(valid[u2'(dataE.alu_commit[i].dst)][0] == 1'b0);
				valid[u2'(dataE.alu_commit[i].dst)][0] = 1'b1;
				write[u2'(dataE.alu_commit[i].dst)][0] = dataE.alu_commit[i];
			end
		end
		for (int i = 0; i < 1; i++) begin
			if (dataE.br_commit[i].valid) begin
				valid[u2'(dataE.br_commit[i].dst)][1] = 1'b1;
				write[u2'(dataE.br_commit[i].dst)][1] = dataE.br_commit[i];
			end
		end
		
	end
	
	

	for (genvar i = 0; i < COMMIT_WIDTH; i++) begin
		fifo_mw1r #(
			.QLEN(32),
			.TYPE(logic[$bits(commit_instr_t)-1:0]),
			.WNUM(WNUM)
		) fifo_mw1r_inst (
			.clk, .reset,
			.valid(valid[i]),
			.write(write[i]),
			.read_valid(self.valid[i]),
			.read(self.instr[i])
		);
	end
	
	always_ff @(posedge clk) begin
		// if (valid[0]) begin
		// 	$display("%x", write[0][0].dst);
		// end
		// if (dataE.alu_commit[0].valid) begin
			// $display("%x", dataE.alu_commit[0].dst);
		// end
		// if (self.valid[0]) begin
		// 	$display("%x", self.instr[0].dst);
		// end
	end
	
	
	assign dataE = creg.dataE;

endmodule

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
	if (WNUM == 1) begin
		addr_t h, t;
		TYPE data[QLEN-1:0];
		assign read_valid = h != t;
		assign read = data[h];
		always_ff @(posedge clk) begin
			if (reset) begin
				h <= '0;
				t <= '0;
			end else begin
				t <= t + valid[0];
				h <= h + read_valid;
			end
		end
		always_ff @(posedge clk) begin
			if (valid) begin
				data[t] <= write;
			end
		end
	end else begin
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
				for (int i = 0; i < WNUM; i++) begin
					t[i] <= i;
				end
				
			end else begin
				h <= h_nxt;
				for (int i = 0; i < WNUM; i++) begin
					t[i] <= i + t_nxt;
				end
			end
		end
		TYPE data[WNUM-1:0][QLEN/WNUM-1:0];
		TYPE reads[WNUM-1:0];
		for (genvar i = 0; i < WNUM; i++) begin
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
			wdata = 'x;
			wen = '0;
			for (int i = 0; i < WNUM; i++) begin
				if (valid[i]) begin
					wdata[bank(t[wnum])] = write[i];
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
					// $display("%x", wdata[i]);
				end
			end
		end
	end
	
endmodule



`endif
