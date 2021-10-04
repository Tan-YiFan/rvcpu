`ifndef __ISSUE_SV
`define __ISSUE_SV

`ifdef VERILATOR
`include "include/interface.svh"
`else
`include "interface.svh"
`endif

module issue
	import common::*;
	import rename_pkg::*;
	import issue_pkg::*;
	import execute_pkg::*;(
	input logic clk, reset,
	ireg_intf.issue ireg,
	sreg_intf.issue sreg,
	wake_intf.issue wake,
	ready_intf.issue ready,
	hazard_intf.issue hazard
);
	rename_data_t dataR;
	issue_data_t dataI;

	iq_entry_t [3:0] entry;
	for (genvar i = 0; i < FETCH_WIDTH; i++) begin
        assign entry[i].valid = 1'b1;
        assign entry[i].dst = dataR.instr[i].dst;
        assign entry[i].src1.valid = dataR.instr[i].src1.valid ? ready.v1[i] : 1'b1;
        assign entry[i].src1.id = dataR.instr[i].src1;
		assign entry[i].src1.pid = dataR.instr[i].psrc1.id;
        assign entry[i].src1.forward_en = dataR.instr[i].src1.valid;
        assign entry[i].src2.valid = dataR.instr[i].src2.valid ? ready.v2[i] : 1'b1;
        assign entry[i].src2.id = dataR.instr[i].src2;
		assign entry[i].src2.pid = dataR.instr[i].psrc2.id;
        assign entry[i].src2.forward_en = dataR.instr[i].src2.valid;
        assign entry[i].ctl = dataR.instr[i].ctl;
        assign entry[i].op = dataR.instr[i].op;
        assign entry[i].imm = dataR.instr[i].imm;
        assign entry[i].pc = dataR.instr[i].pc;
	end
	
	write_req_t [3:0] w_alu;
	write_req_t [1:0][1:0] w_mem;
	write_req_t [3:0] w_br;
	write_req_t [3:0] w_mul;
	for (genvar i = 0; i < 4; i++) begin
		assign w_alu[i].valid = dataR.instr[i].ctl.entry_type == ENTRY_ALU;
		assign w_alu[i].entry = entry[i];
	end

	for (genvar i = 0; i < 2; i++) begin
		for (genvar j = 0; j < 2; j++) begin
			assign w_mem[i][j].valid = dataR.instr[i * 2 + j].ctl.entry_type == ENTRY_MEM;
			assign w_mem[i][j].entry = entry[i * 2 + j];
		end
	end

	for (genvar i = 0; i < 4; i++) begin
		assign w_br[i].valid = dataR.instr[i].ctl.entry_type == ENTRY_BR;
		assign w_br[i].entry = entry[i];
	end

	for (genvar i = 0; i < 4; i++) begin
		assign w_mul[i].valid = dataR.instr[i].ctl.entry_type == ENTRY_MUL;
		assign w_mul[i].entry = entry[i];
	end
	
	u8 full;

	for (genvar i = 0; i < 4; i++) begin
		alu_iqueue #(.QLEN(8)) alu_iqueue_inst (
			.clk, .reset(reset),
			.wen(~|full), .stall(1'b0),
			.write(w_alu[i]),
			.read(),
			.full(full[i])
		);
	end

	for (genvar i = 0; i < 2; i++) begin
		mem_iqueue #(.QLEN(4)) mem_iqueue_inst (
			.clk, .reset(reset),
			.wen(~|full), .stall(),
			.write(w_mem[i]),
			.read(),
			.full(full[i + 4])
		);
	end

	br_iqueue #(.QLEN(4)) br_iqueue_inst (
		.clk, .reset(reset),
		.wen(~|full), .stall(),
		.write(w_br[i]),
		.read(),
		.full(full[i + 6])
	);
	
	mul_iqueue #(.QLEN(4)) mul_iqueue_inst (
		.clk, .reset(reset),
		.wen(~|full), .stall(),
		.write(w_mul[i]),
		.read(),
		.full(full[i + 7])
	);
	
	assign sreg.dataI_nxt = dataI;
	assign dataR = ireg.dataR;
endmodule


`endif
