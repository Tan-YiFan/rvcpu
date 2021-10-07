`ifndef __INTERFACE_SVH
`define __INTERFACE_SVH

`ifdef VERILATOR
`include "include/fetch_pkg.sv"
`include "include/decode_pkg.sv"
`include "include/execute_pkg.sv"
`include "include/memory_pkg.sv"
`include "include/writeback_pkg.sv"
`include "include/forward_pkg.sv"
`include "include/csr_pkg.sv"
`include "include/rename_pkg.sv"
`include "include/source_pkg.sv"
`include "include/issue_pkg.sv"
`endif

import common::*;
import fetch_pkg::*;
import decode_pkg::*;
import execute_pkg::*;
import memory_pkg::*;
import writeback_pkg::*;
import forward_pkg::*;
import csr_pkg::*;
import rename_pkg::*;
import issue_pkg::*;
import source_pkg::*;

interface pcselect_intf();
	pc_t [FETCH_WIDTH-1:0] pcF, pcbranchF;
	u1 [FETCH_WIDTH-1:0] validF, branch_takenF;
	pc_t mepc;

	modport pcselect (input pcF, pcbranchF, validF, branch_takenF);
	modport fetch (output pcF, pcbranchF, validF, branch_takenF);
	modport csr (output mepc);
	modport rob (input mepc);
endinterface

interface freg_intf();
	u64 pc, pc_nxt;

	modport pcselect(output pc_nxt);
	modport freg(output pc, input pc_nxt);
	modport fetch(input pc);
endinterface

interface dreg_intf();
	fetch_data_t dataF, dataF_nxt;

	modport fetch(output dataF_nxt);
	modport dreg(input dataF_nxt, output dataF);
	modport decode(input dataF);
endinterface

interface rreg_intf();
	import decode_pkg::*;
	decode_data_t dataD, dataD_nxt;

	modport decode(output dataD_nxt);
	modport rreg(input dataD_nxt, output dataD);
	modport rename(input dataD);
endinterface

interface ireg_intf();
	import rename_pkg::*;
	rename_data_t dataR, dataR_nxt;
	modport rename(output dataR_nxt);
	modport rreg(input dataR_nxt, output dataR);
	modport issue(input dataR);
endinterface

interface sreg_intf();
	import issue_pkg::*;
	issue_data_t dataI, dataI_nxt;
	modport issue(output dataI_nxt);
	modport ireg(input dataI_nxt, output dataI);
	modport source(input dataI);
endinterface

interface ereg_intf();
	import source_pkg::*;
	source_data_t dataS, dataS_nxt;

	modport source(output dataS_nxt);
	modport sreg(input dataS_nxt, output dataS);
	modport execute(input dataS);
endinterface

interface creg_intf();
	import execute_pkg::*;
	execute_data_t dataE, dataE_nxt;
	modport execute(output dataE_nxt);
	modport creg(input dataE_nxt, output dataE);
	modport commit(input dataE);
endinterface

// interface mreg_intf();
// 	execute_data_t dataE_nxt, dataE;

// 	modport execute(output dataE_nxt);
// 	modport mreg(input dataE_nxt, output dataE);
// 	modport memory(input dataE);
	
// endinterface

// interface wreg_intf();
// 	memory_data_t dataM_nxt, dataM;

// 	modport memory(output dataM_nxt);
// 	modport wreg(input dataM_nxt, output dataM);
// 	modport writeback(input dataM);

// endinterface

interface forward_intf();
	forward_t forwardAD;
	forward_t forwardBD;
	forward_t forwardAE;
	forward_t forwardBE;

	import decode_pkg::*;
	import execute_pkg::*;
	import memory_pkg::*;
	import writeback_pkg::*;
	decoded_instr_t instrD;
	decoded_instr_t instrE;
	memory_data_t dataM;
	writeback_data_t dataW;
	modport forward(output forwardAD, forwardBD, forwardAE, forwardBE,
			input instrD, instrE, dataM, dataW);
	modport decode(input forwardAD, forwardBD, dataM, dataW,
			output instrD);
	modport execute(input forwardAE, forwardBE, dataM, dataW,
			output instrE);
	modport memory(output dataM);
	modport writeback(output dataW);
endinterface 

interface hazard_intf();
	logic stallF, stallD, stallR, stallI, stallS, stallE, stallC,
		      flushD, flushR, flushI, flushS, flushE, flushC;
	u1 branch_miss, iq_full, rob_full;
	modport issue(output iq_full);
	modport rob(output rob_full, branch_miss);
	
	modport hazard (output stallF, stallD, stallR, stallI, stallS, stallE, stallC,
		flushD, flushR, flushI, flushS, flushE, flushC,
					input branch_miss, iq_full, rob_full);
endinterface

interface csr_intf();
	csr_addr_t ra;
	word_t rd;

	u1 valid;
	csr_addr_t wa;
	word_t wd;

	u1 is_mret;
	
	modport source(output ra, input rd);
	modport rob(output valid, wa, wd, is_mret);
	modport csr(input ra, valid, wa, wd, is_mret, output rd);
endinterface

// interface regfile_intf();
// 	creg_addr_t[AREG_READ_PORTS-1:0] ra1, ra2;
// 	word_t[AREG_READ_PORTS-1:0] rd1, rd2;
// 	u1[AREG_WRITE_PORTS-1:0] valid;
// 	creg_addr_t[AREG_WRITE_PORTS-1:0] wa;
// 	word_t[AREG_WRITE_PORTS-1:0] wd;

// 	modport decode(output ra1, ra2, input rd1, rd2);
// 	modport regfile(input ra1, ra2, valid, wa, wd,
// 			output rd1, rd2);
// 	modport writeback(output valid, wa, wd);
// endinterface

interface bp_intf(
	/* From iresp */
	
);

endinterface

interface rename_intf();
	import common::*;
    import decode_pkg::*;
    rob_ptr_t [FETCH_WIDTH-1:0]psrc;
    struct packed {
        logic valid;
        creg_addr_t src1, src2, dst;
        word_t pc;
        control_t ctl;
    } [FETCH_WIDTH-1:0]instr;
    struct packed {
        struct packed {
            logic valid;
            preg_addr_t id;
		} psrc1, psrc2;
    } [FETCH_WIDTH-1:0]info;
    modport rename(
        input info, psrc,
        output instr
    );
    modport rat(
        input psrc, instr, 
        output info
    );
    modport rob(
        input instr,
        output psrc
    );
endinterface

interface retire_intf();
	struct packed {
        logic valid;
        word_t data;
        control_t ctl;
        creg_addr_t dst;
        preg_addr_t preg;
		pc_t pc;
    } [COMMIT_WIDTH-1:0]retire;
	modport rat(
        input retire
    );
	modport regfile (
		input retire
	);
	modport rob (
		output retire
	);
	modport issue (
		input retire
	);
endinterface

interface commit_intf();
	import commit_pkg::*;
	u1 [COMMIT_WIDTH-1:0] valid;
	commit_instr_t [COMMIT_WIDTH-1:0] instr;
	modport commit(output instr, valid);
	modport rob(input instr, valid);
endinterface


interface source_intf();
	import common::*;
	word_t [AREG_READ_PORTS-1:0] arf1, arf2, prf1, prf2;
	creg_addr_t [AREG_READ_PORTS-1:0] src1, src2;
	preg_addr_t [AREG_READ_PORTS-1:0] psrc1, psrc2;
	modport source(output src1, src2, psrc1, psrc2,
					input arf1, arf2, prf1, prf2);
	modport regfile(input src1, src2, output arf1, arf2);
	modport rob(input psrc1, psrc2, output prf1, prf2);
endinterface

interface wake_intf();
	import issue_pkg::*;
	wake_req_t [COMMIT_WIDTH - 1 : 0]wake;
	modport issue(input wake);
	modport rob(output wake);
endinterface

interface ready_intf();
	u1 [FETCH_WIDTH-1:0] v1, v2;
	preg_addr_t [FETCH_WIDTH-1:0] psrc1, psrc2;
	modport issue(input v1, v2, output psrc1, psrc2);
	modport rob(output v1, v2, input psrc1, psrc2);
endinterface

`endif
