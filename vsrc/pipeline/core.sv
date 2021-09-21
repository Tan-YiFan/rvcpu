`ifndef __CORE_SV
`define __CORE_SV
`ifdef VERILATOR
`include "include/interface.svh"
`include "pipeline/fetch/pcselect.sv"
`include "pipeline/fetch/fetch.sv"
`include "pipeline/decode/decode.sv"
`include "pipeline/execute/execute.sv"
`include "pipeline/memory/memory.sv"
`include "pipeline/writeback/writeback.sv"
`include "pipeline/forward/forward.sv"
`include "pipeline/hazard/hazard.sv"
`include "pipeline/regfile/regfile.sv"
`include "pipeline/regfile/pipereg.sv"
`include "pipeline/csr/csr.sv"

`else
`include "interface.svh"
`endif

module core 
	import common::*;
	import fetch_pkg::*;
	import decode_pkg::*;
	import execute_pkg::*;
	import memory_pkg::*;
	import writeback_pkg::*;(
	input logic clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp
);

	u64 pc;
	freg_intf freg_intf();
	dreg_intf dreg_intf();
	ereg_intf ereg_intf();
	mreg_intf mreg_intf();
	wreg_intf wreg_intf();
	pcselect_intf pcselect_intf();
	regfile_intf regfile_intf();
	forward_intf forward_intf();
	hazard_intf hazard_intf();
	csr_intf csr_intf();

	mread_req mread;
	mwrite_req mwrite;
	u64 imin, imax;
	u64 dmin, dmax;
	always_ff @(posedge clk) begin
		if (reset) begin
			// imin <= 64'h8000_0000;
			// imax <= 64'h8000_0000;
			dmin <= 64'h8010_0000;
			dmax <= 64'h8000_0000;
		end else begin
			// if (ireq.addr[31]) begin
			// 	if (ireq.addr < imin) imin <= ireq.addr;
			// 	if (ireq.addr > imax) imax <= ireq.addr;
			// end
			if (dreq.addr[31:28] == 4'd8 && dreq.valid) begin
				$display("%x", dreq.addr[31:0]);
				// if (dreq.addr < dmin) dmin <= dreq.addr;
				// if (dreq.addr > dmax) begin
					// dmax <= dreq.addr;
					// #1 $display("dmin %x, dmax %x", dmin, dmax);
				// end
			end
			// if (ireq.addr == 64'h8000478c) $display("imin %x, imax %x, dmin %x, dmax %x", imin, imax, dmin, dmax);
		end
	end
	


	assign ireq.addr = pc;
	assign ireq.valid = 1'b1;
	always_ff @(posedge clk) begin
		// if (~reset) $display("pc %x", pc);
	end
	
	assign dreq.valid = mread.valid | mwrite.valid;
	assign dreq.addr = mwrite.valid ? mwrite.addr : mread.addr;
	assign dreq.size = mwrite.valid ? mwrite.size : mread.size;
	assign dreq.data = mwrite.data;
	assign dreq.strobe = mwrite.valid ? mwrite.strobe : '0;
	pcselect pcselect(
		.self(pcselect_intf.pcselect),
		.freg(freg_intf.pcselect)
	);
	
	fetch fetch(
		.raw_instr(iresp.data),
		.pc(pc),
		.pcselect(pcselect_intf.fetch),
		.freg(freg_intf.fetch),
		.dreg(dreg_intf.fetch)
	);

	decode decode(
		.clk, .reset,
		.pcselect(pcselect_intf.decode),
		.dreg(dreg_intf.decode),
		.ereg(ereg_intf.decode),
		.forward(forward_intf.decode),
		.hazard(hazard_intf.decode),
		.regfile(regfile_intf.decode),
		.csr(csr_intf.decode)
	);

	execute execute(
		.clk, .reset,
		.ereg(ereg_intf.execute),
		.mreg(mreg_intf.execute),
		.forward(forward_intf.execute),
		.hazard(hazard_intf.execute)
	);

	memory memory(
		.mread, .mwrite, .rd(dresp.data),
		.mreg(mreg_intf.memory),
		.wreg(wreg_intf.memory),
		.forward(forward_intf.memory),
		.hazard(hazard_intf.memory)
	);

	writeback writeback(
		.wreg(wreg_intf.writeback),
		.regfile(regfile_intf.writeback),
		.hazard(hazard_intf.writeback),
		.forward(forward_intf.writeback),
		.csr(csr_intf.writeback)
	);

	regfile regfile(
		.clk, .reset,
		.self(regfile_intf.regfile)
	);

	hazard hazard (
        	.self(hazard_intf.hazard),
		.i_data_ok(iresp.data_ok),
		.d_data_ok(dresp.data_ok | ~dreq.valid)
	);
	forward forward(
		.self(forward_intf.forward)
	);

	csr csr (
		.clk, .reset,
		.self(csr_intf.csr)

	);

	pipereg #(.T(u64), .INIT(PCINIT)) freg(
		.clk, .reset,
		.in(freg_intf.pc_nxt),
		.out(freg_intf.pc),
		.flush(1'b0),
		.en(~hazard_intf.stallF)
	);

	pipereg #(.T(fetch_data_t)) dreg (
		.clk, .reset,
		.in(dreg_intf.dataF_nxt),
		.out(dreg_intf.dataF),
		.flush(hazard_intf.flushD),
		.en(~hazard_intf.stallD)
	);

	pipereg #(.T(decode_data_t)) ereg (
		.clk, .reset,
		.in(ereg_intf.dataD_nxt),
		.out(ereg_intf.dataD),
		.flush(hazard_intf.flushE),
		.en(~hazard_intf.stallE)
	);

	pipereg #(.T(execute_data_t)) mreg (
		.clk, .reset,
		.in(mreg_intf.dataE_nxt),
		.out(mreg_intf.dataE),
		.flush(hazard_intf.flushM),
		.en(~hazard_intf.stallM)
	);

	pipereg #(.T(memory_data_t)) wreg (
		.clk, .reset,
		.in(wreg_intf.dataM_nxt),
		.out(wreg_intf.dataM),
		.flush(hazard_intf.flushW),
		.en(1'b1)
	);

`ifdef VERILATOR
	// u1 commit_valid;
	// assign commit_valid = writeback.pc[31:28] == 4'd8;
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (0),
		.index              (0),
		.valid              (writeback.pc != 64'b0 && writeback.pc != 64'd4),
		.pc                 (writeback.pc - 4),
		.instr              (0),
		.skip               ((wreg_intf.dataM.instr.ctl.memwrite || wreg_intf.dataM.instr.ctl.memread) && ~writeback.result[31]),
		.isRVC              (0),
		.scFailed           (0),
		.wen                (regfile_intf.valid),
		.wdest              (regfile_intf.wa),
		.wdata              (regfile_intf.wd)
	);
	      
	DifftestArchIntRegState DifftestArchIntRegState (
		.clock              (clk),
		.coreid             (0),
		.gpr_0              (regfile.regs_nxt[0]),
		.gpr_1              (regfile.regs_nxt[1]),
		.gpr_2              (regfile.regs_nxt[2]),
		.gpr_3              (regfile.regs_nxt[3]),
		.gpr_4              (regfile.regs_nxt[4]),
		.gpr_5              (regfile.regs_nxt[5]),
		.gpr_6              (regfile.regs_nxt[6]),
		.gpr_7              (regfile.regs_nxt[7]),
		.gpr_8              (regfile.regs_nxt[8]),
		.gpr_9              (regfile.regs_nxt[9]),
		.gpr_10             (regfile.regs_nxt[10]),
		.gpr_11             (regfile.regs_nxt[11]),
		.gpr_12             (regfile.regs_nxt[12]),
		.gpr_13             (regfile.regs_nxt[13]),
		.gpr_14             (regfile.regs_nxt[14]),
		.gpr_15             (regfile.regs_nxt[15]),
		.gpr_16             (regfile.regs_nxt[16]),
		.gpr_17             (regfile.regs_nxt[17]),
		.gpr_18             (regfile.regs_nxt[18]),
		.gpr_19             (regfile.regs_nxt[19]),
		.gpr_20             (regfile.regs_nxt[20]),
		.gpr_21             (regfile.regs_nxt[21]),
		.gpr_22             (regfile.regs_nxt[22]),
		.gpr_23             (regfile.regs_nxt[23]),
		.gpr_24             (regfile.regs_nxt[24]),
		.gpr_25             (regfile.regs_nxt[25]),
		.gpr_26             (regfile.regs_nxt[26]),
		.gpr_27             (regfile.regs_nxt[27]),
		.gpr_28             (regfile.regs_nxt[28]),
		.gpr_29             (regfile.regs_nxt[29]),
		.gpr_30             (regfile.regs_nxt[30]),
		.gpr_31             (regfile.regs_nxt[31])
	);
	      
	DifftestTrapEvent DifftestTrapEvent(
		.clock              (clk),
		.coreid             (0),
		.valid              (0),
		.code               (0),
		.pc                 (0),
		.cycleCnt           (0),
		.instrCnt           (0)
	);
	      
	DifftestCSRState DifftestCSRState(
		.clock              (clk),
		.coreid             (0),
		.priviledgeMode     (0),
		.mstatus            (0),
		.sstatus            (0),
		.mepc               (0),
		.sepc               (0),
		.mtval              (0),
		.stval              (0),
		.mtvec              (0),
		.stvec              (0),
		.mcause             (0),
		.scause             (0),
		.satp               (0),
		.mip                (0),
		.mie                (0),
		.mscratch           (0),
		.sscratch           (0),
		.mideleg            (0),
		.medeleg            (0)
	      );
	      
	DifftestArchFpRegState DifftestArchFpRegState(
		.clock              (clk),
		.coreid             (0),
		.fpr_0              (0),
		.fpr_1              (0),
		.fpr_2              (0),
		.fpr_3              (0),
		.fpr_4              (0),
		.fpr_5              (0),
		.fpr_6              (0),
		.fpr_7              (0),
		.fpr_8              (0),
		.fpr_9              (0),
		.fpr_10             (0),
		.fpr_11             (0),
		.fpr_12             (0),
		.fpr_13             (0),
		.fpr_14             (0),
		.fpr_15             (0),
		.fpr_16             (0),
		.fpr_17             (0),
		.fpr_18             (0),
		.fpr_19             (0),
		.fpr_20             (0),
		.fpr_21             (0),
		.fpr_22             (0),
		.fpr_23             (0),
		.fpr_24             (0),
		.fpr_25             (0),
		.fpr_26             (0),
		.fpr_27             (0),
		.fpr_28             (0),
		.fpr_29             (0),
		.fpr_30             (0),
		.fpr_31             (0)
	);
	
`endif
	always_ff @(posedge clk) begin
		if (~reset) begin
			// $display("ireq: valid %d, pc %x", ireq.valid, ireq.addr);
			if (iresp.data_ok) begin
				// $display("pc 0x%x, raw_instr 0x%x", ireq.addr, iresp.data);
			end
		end
	end
endmodule
`endif