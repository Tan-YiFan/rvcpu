`ifndef __DECODE_SV
`define __DECODE_SV

`ifdef VERILATOR
`include "include/interface.svh"
`include "pipeline/decode/decoder.sv"
`include "pipeline/execute/bru.sv"
`else
`include "interface.svh"
`endif

module decode 
	import common::*;
	import decode_pkg::*;
	import fetch_pkg::*;(
	input logic clk, reset,
	pcselect_intf.decode pcselect,
	dreg_intf.decode dreg,
	ereg_intf.decode ereg,
	regfile_intf.decode regfile,
	forward_intf.decode forward,
	hazard_intf.decode hazard,
	csr_intf.decode csr
);
	decoded_instr_t instr;
	decoder decoder_1 (
		.raw_instr(dreg.dataF.raw_instr),
		.instr(instr)
	);

	word_t rd1, rd2;
	always_comb begin : forwardAD
		unique case(forward.forwardAD)
			FORWARDM: begin
				rd1 = forward.dataM.result;
			end
			FORWARDW: begin
				rd1 = forward.dataW.result;
			end
			default: begin
				rd1 = regfile.rd1;
			end
		endcase
	end : forwardAD

	always_comb begin : forwardBD
		unique case(forward.forwardBD)
			FORWARDM: begin
				rd2 = forward.dataM.result;
			end
			FORWARDW: begin
				rd2 = forward.dataW.result;
			end
			default: begin
				rd2 = regfile.rd2;
			end
		endcase
	end : forwardBD
	
	u1 branch_taken, branch_taken_temp;
	bru bru_1 (
		.branch_type(instr.ctl.branch_type),
		.a(rd1),
		.b(rd2),
		.branch_taken(branch_taken_temp)
	);
	assign branch_taken = branch_taken_temp & instr.ctl.branch;

	/* verilator lint_off UNOPTFLAT */
	decode_data_t dataD;
	assign dataD.instr = instr;
	assign dataD.pc = dreg.dataF.pc;
	assign dataD.rd1 = rd1;
	assign dataD.rd2 = rd2;
	assign dataD.csr = csr.rd;
	assign dataD.writereg = decoder_1.rd;
	assign ereg.dataD_nxt = dataD;

	assign pcselect.pcjump = dreg.dataF.pc + decoder_1.imm_jtype;
	assign pcselect.pcjr = rd1;
	assign pcselect.pcbranch = dreg.dataF.pc + decoder_1.imm_btype;
	assign pcselect.branch_taken = branch_taken;
	assign pcselect.jr = instr.ctl.jr;
	assign pcselect.jump = instr.ctl.jump;

	assign regfile.ra1 = instr.rs1;
	assign regfile.ra2 = instr.rs2;
	assign forward.instrD = dataD.instr;
	assign hazard.dataD = dataD;
	assign hazard.branch_taken = branch_taken | instr.ctl.jump;
	assign csr.ra = instr.csr_addr;

	
endmodule


`endif