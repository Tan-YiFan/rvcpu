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
	u64 regs[31:0];

	for (genvar i = 0; i < READ_PORTS; i++) begin
		assign self.rd1[i] = regs[self.ra1[i]];
		assign self.rd2[i] = regs[self.ra2[i]];
	end

	initial begin
		for (int i = 0; i < 32; i++) begin
			regs[i] = 0;
		end
	end
	always_ff @(posedge clk) begin
		for (int j = 0; j < WRITE_PORTS; j++) begin
			if (self.valid[j]) begin
				regs[self.wa[j]] = self.wd[j];
			end
		end
	end
	
	// for (genvar i = 1; i < 32; i++) begin
	// 	always_comb begin
	// 		regs_nxt[i] = regs[i];
	// 		for (int j = 0; j < WRITE_PORTS; j++) begin
	// 			if (i == self.wa[j] && self.valid[j]) begin
	// 				regs_nxt[i] = self.wd[j];
	// 			end
	// 		end
	// 	end
	// end
		
	

endmodule

module preg 
	import common::*;
	#(
	parameter READ_PORTS = 4,
	parameter WRITE_PORTS = 1
) (
	input logic clk, reset,
	input preg_addr_t [READ_PORTS-1:0] ra1, ra2,
	input preg_addr_t [WRITE_PORTS-1:0] wa,
	input logic[WRITE_PORTS-1:0] valid,
	input u64[WRITE_PORTS-1:0] wd,
	output u64[READ_PORTS-1:0] rd1, rd2
);
	u64 regs[PREG_NUM-1:0];

	for (genvar i = 0; i < READ_PORTS; i++) begin
		assign rd1[i] = regs[ra1[i]];
		assign rd2[i] = regs[ra2[i]];
	end

	initial begin
		for (int i = 0; i < PREG_NUM; i++) begin
			regs[i] = 0;
		end
	end
	always_ff @(posedge clk) begin
		for (int j = 0; j < WRITE_PORTS; j++) begin
			if (valid[j]) begin
				regs[wa[j]] = wd[j];
			end
		end
	end

endmodule

`endif