`ifndef __EXECUTE_SV
`define __EXECUTE_SV

`ifdef VERILATOR
`include "include/interface.svh"
`include "pipeline/execute/alu.sv"
`include "pipeline/execute/bru.sv"
`include "pipeline/execute/multicycle.sv"
`else
`include "interface.svh"
`endif
module execute
	import common::*;
	import decode_pkg::*;
	import execute_pkg::*;
	import source_pkg::*;(
	input logic clk, reset,
	ereg_intf.execute ereg,
	creg_intf.execute creg
	// forward_intf.execute forward
);
	source_data_t dataS;
	execute_data_t dataE;

	word_t [3:0] alu_result;
	word_t [0:0] bru_result, bru_extra;
	word_t [3:0] alusrca, alusrcb;
	for (genvar i = 0; i < 4; i++) begin
		always_comb begin
			alusrca[i] = dataS.alu_source[i].d1;
			if (dataS.alu_source[i].ctl.pc_as_src1) begin
				alusrca[i] = {32'd0, dataS.alu_source[i].pc};
			end
		end
		always_comb begin
			alusrcb[i] = dataS.alu_source[i].d2;
			if (dataS.alu_source[i].ctl.imm_as_src2) begin
				alusrcb[i] = dataS.alu_source[i].imm;
			end
		end
		
	end
	
	for (genvar i = 0; i < 4; i++) begin
		alu alu_inst (
			.a(alusrca[i]),
			.b(alusrcb[i]),
			.c(alu_result[i]),
			.alufunc(dataS.alu_source[i].ctl.alufunc)
		);
	end

	for (genvar i = 0; i < 1; i++) begin
		bru bru_inst (
			.a(dataS.branch_source[i].d1),
			.b(dataS.branch_source[i].d2),
			.imm(dataS.branch_source[i].imm),
			.ctl(dataS.branch_source[i].ctl),
			.pc(dataS.branch_source[i].pc),
			.pcjump('x),
			.jump(1'b0),
			.csr(dataS.csr),
			.data(bru_result[i]),
			.extra(bru_extra[i])
		);
	end
	

	for (genvar i = 0; i < 4; i++) begin
		assign dataE.alu_commit[i].valid = dataS.alu_source[i].valid;
		assign dataE.alu_commit[i].data = alu_result[i];
		assign dataE.alu_commit[i].extra = '0;
		assign dataE.alu_commit[i].dst = dataS.alu_source[i].dst;
	end

	for (genvar i = 0; i < 1; i++) begin
		assign dataE.br_commit[i].valid = dataS.branch_source[i].valid;
		assign dataE.br_commit[i].data = bru_result[i];
		assign dataE.br_commit[i].extra = bru_extra[i];
		assign dataE.br_commit[i].dst = dataS.branch_source[i].dst;
	end
	
	
	always_ff @(posedge clk) begin
		// if (dataS.alu_source[0].valid) begin
			// $display("%x", dataS.alu_source[0].dst);
		// end
		// if (dataE.alu_commit[1].valid) begin
			// $display("%x", dataE.alu_commit[1].data);
		// end
		// if (dataS.alu_source[1].valid) begin
		// 	$display("%x", dataS.alu_source[1].ctl.pc_as_src1);
		// end
	end
	for (genvar i = 0; i < 4; i++) begin
		always_ff @(posedge clk) begin
			if (dataE.alu_commit[i].valid) begin
				// $display("%x %x %x %x", i, dataS.alu_source[i].pc, alusrca[i], alusrcb[i]);
			end
		end
		
	end
	
	

	assign dataS = ereg.dataS;
	assign creg.dataE_nxt = dataE;
endmodule


`endif
