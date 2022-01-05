`ifndef __CORE_SV
`define __CORE_SV
`ifdef VERILATOR
`include "include/interface.svh"
`include "pipeline/fetch/pcselect.sv"
`include "pipeline/fetch/fetch.sv"
`include "pipeline/decode/decode.sv"
`include "pipeline/execute/execute.sv"
`include "pipeline/memory/memory.sv"
// `include "pipeline/writeback/writeback.sv"

// `include "pipeline/forward/forward.sv"
`include "pipeline/hazard/hazard.sv"
`include "pipeline/regfile/regfile.sv"
`include "pipeline/regfile/pipereg.sv"
`include "pipeline/csr/csr.sv"
`include "pipeline/rename/rename.sv"
`include "pipeline/rename/rob.sv"
`include "pipeline/rename/rat.sv"
`include "pipeline/issue/issue.sv"
`include "pipeline/source/source.sv"
`include "pipeline/commit/commit.sv"
`include "pipeline/memory/wbuffer.sv"
`include "pipeline/fetch/bp/branchpredict.sv"
`include "util/SimpleArbiter.sv"

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
	output dbus_req_t[1:0]  dreq,
	input  dbus_resp_t[1:0] dresp,

	output cbus_req_t ureq,
	input cbus_resp_t uresp
);

	u64 pc;
	freg_intf freg_intf();
	dreg_intf dreg_intf();
	rreg_intf rreg_intf();
	ireg_intf ireg_intf();
	sreg_intf sreg_intf();
	ereg_intf ereg_intf();
	creg_intf creg_intf();
	// mreg_intf mreg_intf();
	// wreg_intf wreg_intf();
	pcselect_intf pcselect_intf();
	// regfile_intf regfile_intf();
	forward_intf forward_intf();
	hazard_intf hazard_intf();
	csr_intf csr_intf();
	source_intf source_intf();
	retire_intf retire_intf();
	rename_intf rename_intf();
	commit_intf commit_intf();
	wake_intf wake_intf();
	ready_intf ready_intf();
	wbuffer_intf wbuffer_intf();
	bp_intf bp_intf();

	// mread_req mread;
	// mwrite_req mwrite;
	dbus_req_t [RMEM_WIDTH-1:0] rreq;
	dbus_resp_t [RMEM_WIDTH-1:0] rresp;
	dbus_req_t [WMEM_WIDTH-1:0] wreq;
	dbus_resp_t [WMEM_WIDTH-1:0] wresp;

	assign ireq.addr = pc;
	assign ireq.valid = 1'b1;
	always_ff @(posedge clk) begin
		// if (~reset) $display("pc %x", pc);
	end
	
	// assign dreq.valid = mread.valid | mwrite.valid;
	// assign dreq.addr = mwrite.valid ? mwrite.addr : mread.addr;
	// assign dreq.size = mwrite.valid ? mwrite.size : mread.size;
	// assign dreq.data = mwrite.data;
	// assign dreq.strobe = mwrite.valid ? mwrite.strobe : '0;
	SimpleArbiter sc (
		.clk, .reset,
		.rreq,
		.wreq,
		.dresp(dresp),

		.dreq(dreq),
		.rresp,
		.wresp
	);
	pcselect pcselect(
		.self(pcselect_intf.pcselect),
		.freg(freg_intf.pcselect)
	);
	
	fetch fetch(
		.iresp,
		.pc(pc),
		.pcselect(pcselect_intf.fetch),
		.freg(freg_intf.fetch),
		.dreg(dreg_intf.fetch),
		.bp(bp_intf.fetch)
	);

	decode decode(
		.clk, .reset,
		.dreg(dreg_intf.decode),
		.rreg(rreg_intf.decode)
	);

	rename rename (
		.rreg(rreg_intf.rename),
		.ireg(ireg_intf.rename),
		.self(rename_intf.rename)
	);

	issue issue (
		.clk, .reset(reset | hazard_intf.flushC),
		.ireg(ireg_intf.issue),
		.sreg(sreg_intf.issue),
		.wake(wake_intf.issue),
		.ready(ready_intf.issue),
		.retire(retire_intf.issue),
		.hazard(hazard_intf.issue),
		.d_data_ok((dresp[0].data_ok || ~dreq[0].valid) && (dresp[1].data_ok || ~dreq[1].valid))
	);

	source source (
		.sreg(sreg_intf.source),
		.ereg(ereg_intf.source),
		.self(source_intf.source),
		.csr(csr_intf.source)
	);

	execute execute(
		.clk, .reset(reset | hazard_intf.flushC),
		.ereg(ereg_intf.execute),
		.creg(creg_intf.execute),
		.wbuffer(wbuffer_intf.execute),
		.rreq,
		.rresp
	);

	commit commit (
		.clk, .reset(reset | hazard_intf.flushC),
		.creg(creg_intf.commit),
		.self(commit_intf.commit)
	);

	// memory memory(
	// 	.mread, .mwrite, .rd(dresp.data),
	// 	.mreg(mreg_intf.memory),
	// 	.wreg(wreg_intf.memory),
	// 	.forward(forward_intf.memory),
	// 	.hazard(hazard_intf.memory)
	// );

	// writeback writeback(
	// 	.wreg(wreg_intf.writeback),
	// 	.regfile(regfile_intf.writeback),
	// 	.hazard(hazard_intf.writeback),
	// 	.forward(forward_intf.writeback),
	// 	.csr(csr_intf.writeback),
	// 	.rd(dresp.data)
	// );

	regfile regfile(
		.clk, .reset,
		.source(source_intf.regfile),
		.retire(retire_intf.regfile)
		// .self(regfile_intf.regfile)
	);

	hazard hazard (
        	.self(hazard_intf.hazard),
		.i_data_ok(iresp.data_ok),
		.d_data_ok((dresp[0].data_ok || ~dreq[0].valid) && (dresp[1].data_ok || ~dreq[1].valid))
	);
	// forward forward(
	// 	.self(forward_intf.forward)
	// );

	csr csr (
		.clk, .reset,
		.self(csr_intf.csr)
	);

	rob rob (
		.clk, .reset(reset | hazard_intf.flushC),
		.rename(rename_intf.rob),
		.commit(commit_intf.rob),
		.retire(retire_intf.rob),
		.hazard(hazard_intf.rob),
		.pcselect(pcselect_intf.rob),
		.ready(ready_intf.rob),
		.wake(wake_intf.rob),
		.source(source_intf.rob),
		.bp(bp_intf.rob),
		.wbuffer(wbuffer_intf.rob),
		.dresp(wresp),
		.ureq,
		.uresp
	);

	rat rat (
		.clk, .reset(reset | hazard_intf.flushC),
		.rename(rename_intf.rat),
		.retire(retire_intf.rat)
	);

	pipereg #(.T(pc_t), .INIT(PCINIT)) freg(
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

	pipereg #(.T(decode_data_t)) rreg (
		.clk, .reset,
		.in(rreg_intf.dataD_nxt),
		.out(rreg_intf.dataD),
		.flush(hazard_intf.flushR),
		.en(~hazard_intf.stallR)
	);

	pipereg #(.T(rename_data_t)) ireg (
		.clk, .reset,
		.in(ireg_intf.dataR_nxt),
		.out(ireg_intf.dataR),
		.flush(hazard_intf.flushI),
		.en(~hazard_intf.stallI)
	);

	pipereg #(.T(issue_data_t)) sreg (
		.clk, .reset,
		.in(sreg_intf.dataI_nxt),
		.out(sreg_intf.dataI),
		.flush(hazard_intf.flushS),
		.en(~hazard_intf.stallS)
	);

	pipereg #(.T(source_data_t)) ereg (
		.clk, .reset,
		.in(ereg_intf.dataS_nxt),
		.out(ereg_intf.dataS),
		.flush(hazard_intf.flushE),
		.en(~hazard_intf.stallE)
	);

	pipereg #(.T(execute_data_t)) creg (
		.clk, .reset,
		.in(creg_intf.dataE_nxt),
		.out(creg_intf.dataE),
		.flush(hazard_intf.flushC),
		.en(~hazard_intf.stallC)
	);

	wbuffer_module wbuffer_inst (
		.clk, .reset(reset | hazard_intf.flushC),
		.self(wbuffer_intf.wbuffer),
		.oreq(wreq),
		.oresp(wresp)
	);

	branchpredict branchpredict (
		.clk, .reset,
		.self(bp_intf.bp)
	);

`ifdef VERILATOR
	// u1 commit_valid;
	// assign commit_valid = writeback.pc[31:28] == 4'd8;
	// DifftestInstrCommit DifftestInstrCommit(
	// 	.clock              (clk),
	// 	.coreid             (0),
	// 	.index              (0),
	// 	.valid              (writeback.pc != 64'b0 && writeback.pc != 64'd4),
	// 	.pc                 (writeback.pc - 4),
	// 	.instr              (0),
	// 	.skip               ((wreg_intf.dataM.instr.ctl.memwrite || wreg_intf.dataM.instr.ctl.memread) && ~writeback.result[31]),
	// 	.isRVC              (0),
	// 	.scFailed           (0),
	// 	.wen                (regfile_intf.valid),
	// 	.wdest              (regfile_intf.wa),
	// 	.wdata              (regfile_intf.wd)
	// );
	for (genvar i = 0; i < COMMIT_WIDTH; i++) begin
		DifftestInstrCommit DifftestInstrCommit(
			.clock              (clk),
			.coreid             (0),
			.index              (i),
			.valid              (retire_intf.retire[i].valid),
			.pc                 (retire_intf.retire[i].pc),
			.instr              (0),
			.skip               (/* retire_intf.retire[i].uncached */retire_intf.retire[i].pc == 'h80002684),
			.isRVC              (0),
			.scFailed           (0),
			.wen                (retire_intf.retire[i].ctl.regwrite),
			.wdest              (retire_intf.retire[i].dst),
			.wdata              (retire_intf.retire[i].data)
		);
		
	end
	
	      
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
		.priviledgeMode     (3),
		.mstatus            (csr.regs_nxt.mstatus),
		.sstatus            (csr.regs_nxt.mstatus & 64'h800000030001e000),
		.mepc               (csr.regs_nxt.mepc),
		.sepc               (0),
		.mtval              (csr.regs_nxt.mtval),
		.stval              (0),
		.mtvec              (csr.regs_nxt.mtvec),
		.stvec              (0),
		.mcause             (csr.regs_nxt.mcause),
		.scause             (0),
		.satp               (0),
		.mip                (csr.regs_nxt.mip),
		.mie                (0),
		.mscratch           (csr.regs_nxt.mscratch),
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
				// $display("pc %x, raw_instr %x", ireq.addr, iresp.data[0].raw_instr);
			end
		end
	end
endmodule
`endif