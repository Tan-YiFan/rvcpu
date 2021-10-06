`ifndef __ISSUE_SV
`define __ISSUE_SV

`ifdef VERILATOR
`include "include/interface.svh"
`include "pipeline/issue/alu_iqueue.sv"
`include "pipeline/issue/mem_iqueue.sv"
`include "pipeline/issue/br_iqueue.sv"
`include "pipeline/issue/mul_iqueue.sv"
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
	retire_intf.issue retire,
	hazard_intf.issue hazard
);
	rename_data_t dataR;
	issue_data_t dataI;

	iq_entry_t [FETCH_WIDTH-1:0] entry;
	for (genvar i = 0; i < FETCH_WIDTH; i++) begin
        assign entry[i].valid = 1'b1;
        assign entry[i].dst = dataR.instr[i].pdst;
        assign entry[i].src1.valid = dataR.instr[i].psrc1.valid ? ready.v1[i] : 1'b1;
        assign entry[i].src1.id = dataR.instr[i].src1;
		assign entry[i].src1.pid = dataR.instr[i].psrc1.id;
        assign entry[i].src1.forward_en = dataR.instr[i].psrc1.valid;
        assign entry[i].src2.valid = dataR.instr[i].psrc2.valid ? ready.v2[i] : 1'b1;
        assign entry[i].src2.id = dataR.instr[i].src2;
		assign entry[i].src2.pid = dataR.instr[i].psrc2.id;
        assign entry[i].src2.forward_en = dataR.instr[i].psrc2.valid;
        assign entry[i].ctl = dataR.instr[i].ctl;
        // assign entry[i].op = dataR.instr[i].op;
        assign entry[i].imm = dataR.instr[i].imm;
        assign entry[i].pc = dataR.instr[i].pc;
	end
	
	write_req_t [3:0] w_alu;
	
	write_req_t [1:0][1:0] w_mem;
	write_req_t [3:0] w_br;
	write_req_t [3:0] w_mul;
	read_resp_t [3:0] r_alu;
	read_resp_t [1:0][1:0] r_mem;
	read_resp_t [3:0] r_br;
	read_resp_t [3:0] r_mul;
	for (genvar i = 0; i < 4; i++) begin
		assign w_alu[i].valid = dataR.instr[i].valid && dataR.instr[i].ctl.entry_type == ENTRY_ALU;
		assign w_alu[i].entry = entry[i];
	end

	for (genvar i = 0; i < 2; i++) begin
		for (genvar j = 0; j < 2; j++) begin
			assign w_mem[i][j].valid = dataR.instr[i * 2 + j].valid && dataR.instr[i * 2 + j].ctl.entry_type == ENTRY_MEM;
			assign w_mem[i][j].entry = entry[i * 2 + j];
		end
	end

	for (genvar i = 0; i < 4; i++) begin
		assign w_br[i].valid = dataR.instr[i].valid && dataR.instr[i].ctl.entry_type == ENTRY_BR;
		assign w_br[i].entry = entry[i];
	end

	for (genvar i = 0; i < 4; i++) begin
		assign w_mul[i].valid = dataR.instr[i].valid && dataR.instr[i].ctl.entry_type == ENTRY_MUL;
		assign w_mul[i].entry = entry[i];
	end
	
	u8 full;

	wake_req_t [COMMIT_WIDTH-1:0] wake_retire;
	for (genvar i = 0; i < COMMIT_WIDTH; i++) begin
		assign wake_retire[i].valid = retire.retire[i].valid;
		assign wake_retire[i].id = retire.retire[i].preg;
	end
	

	for (genvar i = 0; i < 4; i++) begin
		alu_iqueue #(.QLEN(8)) alu_iqueue_inst (
			.clk, .reset(reset),
			.wen(~|full), .stall(1'b0),
			.write(w_alu[i]),
			.read(r_alu[i]),
			.full(full[i]),
			.wake(wake.wake),
			.retire(wake_retire)
		);
	end

	for (genvar i = 0; i < 2; i++) begin
		mem_iqueue #(.QLEN(4)) mem_iqueue_inst (
			.clk, .reset(reset),
			.wen(~|full), .stall(),
			.write(w_mem[i]),
			.read(),
			.full(full[i + 4]),
			.wake(),
			.retire()
		);
	end

	br_iqueue #(.QLEN(4)) br_iqueue_inst (
		.clk, .reset(reset),
		.wen(~|full), .stall(),
		.write(w_br),
		.read(),
		.full(full[6]),
		.wake(),
		.retire()
	);
	
	mul_iqueue #(.QLEN(4)) mul_iqueue_inst (
		.clk, .reset(reset),
		.wen(~|full), .stall(),
		.write(w_mul),
		.read(),
		.full(full[7]),
		.wake(),
		.retire()
	);

	for (genvar i = 0; i < 4; i++) begin
		assign dataI.alu_issue[i].valid = r_alu[i].entry.valid;
		assign dataI.alu_issue[i].imm = r_alu[i].entry.imm;
		assign dataI.alu_issue[i].src1 = r_alu[i].entry.src1.id;
		assign dataI.alu_issue[i].src2 = r_alu[i].entry.src2.id;
		assign dataI.alu_issue[i].psrc1 = r_alu[i].entry.src1.pid;
		assign dataI.alu_issue[i].psrc2 = r_alu[i].entry.src2.pid;
		assign dataI.alu_issue[i].dst = preg_addr_t'(r_alu[i].entry.dst);
		assign dataI.alu_issue[i].forward_en1 = r_alu[i].entry.src1.forward_en;
		assign dataI.alu_issue[i].forward_en2 = r_alu[i].entry.src2.forward_en;
		assign dataI.alu_issue[i].ctl = r_alu[i].entry.ctl;
		assign dataI.alu_issue[i].pc = r_alu[i].entry.pc;

	end

	for (genvar i = 0; i < FETCH_WIDTH; i++) begin
		assign ready.psrc1[i] = dataR.instr[i].psrc1.id;
		assign ready.psrc2[i] = dataR.instr[i].psrc2.id;
	end
	
	
	always_ff @(posedge clk) begin
		// if (dataI.alu_issue[2].valid) begin
		// 	$display("%x", dataI.alu_issue[2].pc);
		// end
		// if (dataR.instr[2].valid) begin
		// 	$display("%x", dataR.instr[2].pc);
		// end
	end

	for (genvar i = 0; i < 4; i++) begin
		always_ff @(posedge clk) begin
			if (dataI.alu_issue[i].dst == 2 && dataI.alu_issue[i].valid) begin
				$display("%x", dataI.alu_issue[i].pc);
			end
		end
		
		
	end
	
	
	assign sreg.dataI_nxt = dataI;
	assign dataR = ireg.dataR;
endmodule


`endif
