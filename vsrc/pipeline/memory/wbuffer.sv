`ifndef __WBUFFER_SV
`define __WBUFFER_SV

`ifdef VERILATOR
`include "include/interface.svh"
`else
`include "interface.svh"
`endif
/* FIFO 2w2r */
module wbuffer_module
	import common::*;
	import memory_pkg::*;
	#(
		parameter QLEN = 64,
		localparam type addr_t = logic[$clog2(QLEN)-1:0],
		localparam type ptr_t = logic[$clog2(QLEN):0]
	)(
	input logic clk, reset,
	wbuffer_intf.wbuffer self,
	output dbus_req_t[WMEM_WIDTH-1:0] oreq,
	input dbus_resp_t[WMEM_WIDTH-1:0] oresp
);
	wbuffer_entry_t [QLEN-1:0] wbuffer;
	ptr_t t[1:0], t_nxt, h[1:0], h_nxt;
	u1 full;

	always_comb begin
		full = '0;
		for (int i = 0; i < 2; i++) 
			if (addr_t'(t[i]) == addr_t'(h[0]) && t[i][$bits(addr_t)] != h[0][$bits(addr_t)]) full = '1;
	end

	always_ff @(posedge clk) begin
		if (full) $finish;
	end
	
	
	for (genvar i = 0; i < WMEM_WIDTH; i++) begin
		always_ff @(posedge clk) begin
			if (oreq[i].valid && oresp[i].data_ok) $display("w%x %x", oreq[i].addr, i);
			// if(self.wreq[i].valid) $display("w%x", self.wreq[i].addr);
		end
		
	end
	
	
	/* Read */
	for (genvar i = 0; i < RMEM_WIDTH; i++) begin
		always_comb begin
			self.rresp[i].valid = '0;
			self.rresp[i].data = 'x;

			/* From the oldest(head) to the newest(tail) */
			for (int j = 0; j < QLEN * 2; j++) begin
				if (addr_t'(j) != h[0]) continue;
				if (addr_t'(j) == t[0]) break;
				if (wbuffer[addr_t'(j)].valid && self.rreq[i].addr[31:3] == wbuffer[addr_t'(j)].addr[31:3]) begin
					self.rresp[i].valid |= wbuffer[addr_t'(j)].strobe;
					for (int k = 0; k < 8; k++) begin
						if (wbuffer[addr_t'(j)].strobe[k]) begin
							self.rresp[i].data[k] = wbuffer[addr_t'(j)].data[k];
						end
					end
				end
			end
		end
	end
	/* Write */
	always_ff @(posedge clk) begin
		if (reset) begin
			t[0] <= '0;
			t[1] <= 1;
		end else if (self.wreq[0].valid && self.wreq[1].valid) begin
			wbuffer[t[0]] <= self.wreq[0];
			wbuffer[t[1]] <= self.wreq[1];
			t[0] <= t[0] + 2;
			t[1] <= t[1] + 2;
		end else if (self.wreq[0].valid) begin
			wbuffer[t[0]] <= self.wreq[0];
			t[0] <= t[0] + 1;
			t[1] <= t[1] + 1;
		end else if (self.wreq[1].valid) begin
			wbuffer[t[0]] <= self.wreq[1];
			t[0] <= t[0] + 1;
			t[1] <= t[1] + 1;
		end
	end
	/* Commit */
	for (genvar i = 0; i < WMEM_WIDTH; i++) begin
		assign oreq[i].valid = wbuffer[addr_t'(h[i])].valid && self.creq[i].valid;
		assign oreq[i].addr = wbuffer[addr_t'(h[i])].addr;
		assign oreq[i].size = wbuffer[addr_t'(h[i])].msize;
		assign oreq[i].strobe = wbuffer[addr_t'(h[i])].strobe;
		assign oreq[i].data = wbuffer[addr_t'(h[i])].data;
	end
	
	always_ff @(posedge clk) begin
		if (reset) begin
			h[0] <= '0;
			h[1] <= 1;
		end else if (oreq[0].valid && oreq[1].valid) begin
			if (oresp[0].data_ok && oresp[1].data_ok) begin
				h[0] <= h[0] + 2;
				h[1] <= h[1] + 2;
			end
		end else if (oreq[0].valid && oresp[0].data_ok) begin
			h[0] <= h[0] + 1;
			h[1] <= h[1] + 1;
		end
	end
	always_ff @(posedge clk) begin
		// $display(h[0], t[0]);
	end
	

endmodule


`endif
