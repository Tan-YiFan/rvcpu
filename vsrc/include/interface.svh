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
`endif

import common::*;
import fetch_pkg::*;
import decode_pkg::*;
import execute_pkg::*;
import memory_pkg::*;
import writeback_pkg::*;
import forward_pkg::*;
import csr_pkg::*;

interface pcselect_intf();
	u1 branch_taken;
	u64 pcbranch;

	u1 jr;
	u64 pcjr;

	u1 jump;
	u64 pcjump;

	u64 pcplus4F;

	modport pcselect(input pcplus4F, pcbranch, pcjr, pcjump,
			 input branch_taken, jr, jump);
	modport fetch(output pcplus4F);
	modport decode(output pcbranch, pcjr, pcjump,
		       output branch_taken, jr, jump);
			 
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

interface ereg_intf();
	import decode_pkg::*;
	decode_data_t dataD, dataD_nxt;

	modport decode(output dataD_nxt);
	modport dreg(input dataD_nxt, output dataD);
	modport execute(input dataD);
endinterface

interface mreg_intf();
	execute_data_t dataE_nxt, dataE;

	modport execute(output dataE_nxt);
	modport mreg(input dataE_nxt, output dataE);
	modport memory(input dataE);
	
endinterface

interface wreg_intf();
	memory_data_t dataM_nxt, dataM;

	modport memory(output dataM_nxt);
	modport wreg(input dataM_nxt, output dataM);
	modport writeback(input dataM);

endinterface

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
	logic stallF, stallD, stallE, stallM,
		      flushD, flushE, flushM, flushW;

	import decode_pkg::*;
	import execute_pkg::*;
	import memory_pkg::*;
	import writeback_pkg::*;
	decode_data_t dataD;
	execute_data_t dataE;
	memory_data_t dataM;
	writeback_data_t dataW;
	u1 mult_ok;
	u1 branch_taken;

	modport decode(output dataD, branch_taken);
	modport execute(output dataE, mult_ok);
	modport memory(output dataM);
	modport writeback(output dataW);

	modport hazard(
		input dataD, dataE, dataM, dataW, mult_ok, branch_taken,
		output stallF, stallD, stallE, stallM, flushD, flushE, flushM, flushW
	);
endinterface

interface csr_intf();
	csr_addr_t ra;
	word_t rd;

	u1 valid;
	csr_addr_t wa;
	word_t wd;
	
	modport decode(output ra, input rd);
	modport writeback(output valid, wa, wd);
	modport csr(input ra, valid, wa, wd, output rd);
endinterface

interface regfile_intf();
	creg_addr_t[AREG_READ_PORTS-1:0] ra1, ra2;
	word_t[AREG_READ_PORTS-1:0] rd1, rd2;
	u1[AREG_WRITE_PORTS-1:0] valid;
	creg_addr_t[AREG_WRITE_PORTS-1:0] wa;
	word_t[AREG_WRITE_PORTS-1:0] wd;

	modport decode(output ra1, ra2, input rd1, rd2);
	modport regfile(input ra1, ra2, valid, wa, wd,
			output rd1, rd2);
	modport writeback(output valid, wa, wd);
endinterface

`endif
