`ifndef __SOURCE_SV
`define __SOURCE_SV

`ifdef VERILATOR
`include "include/interface.svh"
`else
`include "interface.svh"
`endif

module source
	import common::*;
	import issue_pkg::*;
	import source_pkg::*;(
	sreg_intf.source sreg,
	ereg_intf.source ereg,
	source_intf.source self
);
	issue_data_t dataI;
	source_data_t dataS;

	word_t [AREG_READ_PORTS-1:0] rd1, rd2;
	u1 [AREG_READ_PORTS-1:0] f1, f2;
	for (genvar i = 0; i < AREG_READ_PORTS; i++) begin
		always_comb begin
			rd1[i] = self.arf1[i];
			if (f1[i]) begin
				rd1[i] = self.prf1[i];
			end
		end
		always_comb begin
			rd2[i] = self.arf2[i];
			if (f2[i]) begin
				rd2[i] = self.prf2[i];
			end
		end
	end

	for (genvar i = 0; i < 4; i++) begin
		assign self.src1[i] = dataI.alu_issue[i].src1;
		assign self.src2[i] = dataI.alu_issue[i].src2;
		assign self.psrc1[i] = dataI.alu_issue[i].psrc1;
		assign self.psrc2[i] = dataI.alu_issue[i].psrc2;
		assign f1[i] = dataI.alu_issue[i].forward_en1;
		assign f2[i] = dataI.alu_issue[i].forward_en2;
	end
	for (genvar i = 0; i < 2; i++) begin
		assign self.src1[i + 4] = dataI.mem_issue[i].src1;
		assign self.src2[i + 4] = dataI.mem_issue[i].src2;
		assign self.psrc1[i + 4] = dataI.mem_issue[i].psrc1;
		assign self.psrc2[i + 4] = dataI.mem_issue[i].psrc2;
		assign f1[i + 4] = dataI.mem_issue[i].forward_en1;
		assign f2[i + 4] = dataI.mem_issue[i].forward_en2;
	end
	for (genvar i = 0; i < 1; i++) begin
		assign self.src1[i + 6] = dataI.branch_issue[i].src1;
		assign self.src2[i + 6] = dataI.branch_issue[i].src2;
		assign self.psrc1[i + 6] = dataI.branch_issue[i].psrc1;
		assign self.psrc2[i + 6] = dataI.branch_issue[i].psrc2;
		assign f1[i + 6] = dataI.branch_issue[i].forward_en1;
		assign f2[i + 6] = dataI.branch_issue[i].forward_en2;
	end
	for (genvar i = 0; i < 1; i++) begin
		assign self.src1[i + 7] = dataI.mult_issue[i].src1;
		assign self.src2[i + 7] = dataI.mult_issue[i].src2;
		assign self.psrc1[i + 7] = dataI.mult_issue[i].psrc1;
		assign self.psrc2[i + 7] = dataI.mult_issue[i].psrc2;
		assign f1[i + 7] = dataI.mult_issue[i].forward_en1;
		assign f2[i + 7] = dataI.mult_issue[i].forward_en2;
	end
	// for (genvar i = 0; i < AREG_READ_PORTS; i++) begin
	// 	assign forward.psrc1[i] = self.psrc1[i];
	// 	assign forward.psrc2[i] = self.psrc2[i];	
	// end
	
	
	for (genvar i = 0; i < 4; i++) begin
		assign dataS.alu_source[i] = {
			dataI.alu_issue[i].valid,
			rd1[i],
			rd2[i],
			dataI.alu_issue[i].imm,
			dataI.alu_issue[i].src1,
			dataI.alu_issue[i].src2,
			dataI.alu_issue[i].psrc1,
			dataI.alu_issue[i].psrc2,
			dataI.alu_issue[i].dst,
			dataI.alu_issue[i].forward_en1,
			dataI.alu_issue[i].forward_en2,
			dataI.alu_issue[i].ctl,
			dataI.alu_issue[i].pc
		};
	end

	assign dataI = sreg.dataI;
	assign ereg.dataS_nxt = dataS;
	
endmodule


`endif
