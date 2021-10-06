`ifndef __REGFILE_SV
`define __REGFILE_SV
`ifdef VERILATOR
`include "include/interface.svh"
`else
`include "interface.svh"
`endif
module regfile 
	import common::*;
	#(
	parameter READ_PORTS = AREG_READ_PORTS,
	parameter WRITE_PORTS = AREG_WRITE_PORTS
) (
	input logic clk, reset,
	regfile_intf.regfile self
);
	u64 [31:0] regs, regs_nxt;

	for (genvar i = 0; i < READ_PORTS; i++) begin
		assign self.rd1[i] = regs[self.ra1[i]];
		assign self.rd2[i] = regs[self.ra2[i]];
	end

	always_ff @(posedge clk) begin
		if (reset) begin
			regs <= '0;
		end else begin
			regs <= regs_nxt;
		end
	end
	
	for (genvar i = 1; i < 32; i++) begin
		always_comb begin
			regs_nxt[i] = regs[i];
			for (int j = 0; j < WRITE_PORTS; j++) begin
				if (i == self.wa[j] && self.valid[j]) begin
					regs_nxt[i] = self.wd[j];
				end
			end
		end
	end
		
	

endmodule



`endif