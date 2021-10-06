`ifndef __RENAME_SV
`define __RENAME_SV

`ifdef VERILATOR
`include "include/interface.svh"
`include "pipeline/rename/raw_check.sv"
`else
`include "interface.svh"
`endif

module rename
	import common::*;
	import rename_pkg::*;
	import decode_pkg::*; (
	rreg_intf.rename rreg,
	ireg_intf.rename ireg,
	rename_intf.rename self
);
	decode_data_t dataD;
	rename_data_t dataR;
	creg_addr_t [FETCH_WIDTH-1:0] src1, src2, dst;
    for (genvar i = 0; i < FETCH_WIDTH; i++) begin
        assign src1[i] = dataD.instr[i].instr.src1;
    end
    for (genvar i = 0; i < FETCH_WIDTH; i++) begin
        assign src2[i] = dataD.instr[i].instr.src2;
    end
    for (genvar i = 0; i < FETCH_WIDTH; i++) begin
        assign dst[i] = dataD.instr[i].instr.dst;
    end
	struct packed {
        logic valid;
        preg_addr_t id;
    } [FETCH_WIDTH-1:0] psrc1, psrc2, psrc1_rat, psrc2_rat, pdst_fl;
    for (genvar i = 0; i < FETCH_WIDTH ; i++) begin
        assign psrc1_rat[i] =  self.info[i].psrc1;
        assign psrc2_rat[i] =  self.info[i].psrc2;
        assign pdst_fl[i] = self.info[i].pdst;
    end
    raw_check raw_check(.psrc1_rat,
                        .psrc2_rat,
                        .pdst_fl,
                        .src1,
                        .src2,
                        .dst,
                        .psrc1,
                        .psrc2);

	for (genvar i = 0; i < FETCH_WIDTH ; i++) begin
		assign dataR.instr[i].valid = dataD.instr[i].valid;
		assign dataR.instr[i].pdst = self.psrc[i];
		assign dataR.instr[i].psrc1 = psrc1[i];
		assign dataR.instr[i].psrc2 = psrc2[i];
		assign dataR.instr[i].dst = dataD.instr[i].instr.dst;
		assign dataR.instr[i].src1 = dataD.instr[i].instr.src1;
		assign dataR.instr[i].src2 = dataD.instr[i].instr.src2;
		assign dataR.instr[i].ctl = dataD.instr[i].instr.ctl;
		assign dataR.instr[i].op = dataD.instr[i].instr.op;
		assign dataR.instr[i].imm = dataD.instr[i].instr.imm;
		assign dataR.instr[i].pc = dataD.instr[i].pc;
		assign dataR.instr[i].jump = dataD.instr[i].jump;
		assign dataR.instr[i].pcjump = dataD.instr[i].pcjump;
	end
	
	for (genvar i = 0; i < FETCH_WIDTH ; i++) begin
		assign self.instr[i].valid = dataD.instr[i].valid;
		assign self.instr[i].src1 = dataD.instr[i].instr.src1;
		assign self.instr[i].src2 = dataD.instr[i].instr.src2;
		assign self.instr[i].dst = dataD.instr[i].instr.dst;
		assign self.instr[i].pc = dataD.instr[i].pc;
		assign self.instr[i].ctl = dataD.instr[i].instr.ctl;
	end
	assign dataD = rreg.dataD;
    assign ireg.dataR_nxt = dataR;
endmodule


`endif
