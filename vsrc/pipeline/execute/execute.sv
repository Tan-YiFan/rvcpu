`ifndef __EXECUTE_SV
`define __EXECUTE_SV

`ifdef VERILATOR
`include "include/interface.svh"
`include "pipeline/execute/alu.sv"
`include "pipeline/execute/multicycle.sv"
`else
`include "interface.svh"
`endif
module execute
	import common::*;
	import decode_pkg::*;
	import execute_pkg::*; (
	input logic clk, reset,
	ereg_intf.execute ereg,
	mreg_intf.execute mreg,
	forward_intf.execute forward,
	hazard_intf.execute hazard
);

	u64 alusrca, alusrcb;
	u64 writedata;
	u64 aluout, multout;

	always_comb begin : forwardAE
		if (ereg.dataD.instr.ctl.pc_as_src1) alusrca = ereg.dataD.pc;
		else unique case(forward.forwardAE)
			FORWARDM: begin
				alusrca = forward.dataM.result;
			end
			default: begin
				alusrca = ereg.dataD.rd1;
			end
		endcase
	end : forwardAE
	always_comb begin : forwardBE
		unique case(forward.forwardBE)
			FORWARDM: begin
				writedata = forward.dataM.result;
			end
			default: begin
				writedata = ereg.dataD.rd2;
			end
		endcase
	end : forwardBE

	assign alusrcb = ereg.dataD.instr.ctl.imm_as_src2 ? 
                     ereg.dataD.instr.imm : writedata;

	alu alu_inst(
		.a(alusrca),
		.b(alusrcb),
		.alufunc(ereg.dataD.instr.ctl.alufunc),
		.c(aluout)
	);

	multicycle multicycle_inst (
        .clk, .reset,
        .a(alusrca),
        .b(alusrcb),
        .is_multdiv(ereg.dataD.instr.ctl.is_multdiv),
        .flush(1'b0),
        .mult_type(ereg.dataD.instr.ctl.mult_type),
        .c(multout),
        .mult_ok(hazard.mult_ok)
	);

	/* verilator lint_off UNOPTFLAT */
	execute_data_t dataE;
	assign dataE.instr = ereg.dataD.instr;
	// assign dataE.aluout = ereg.dataD.instr.ctl.is_link ? (ereg.dataD.pc + 64'd4) : aluout;
	always_comb begin
		dataE.result = 'x;
		unique if (ereg.dataD.instr.ctl.link) begin
			dataE.result = ereg.dataD.pc + 64'd4;
		end else if (ereg.dataD.instr.ctl.is_multdiv) begin
			dataE.result = multout;
		end else begin
			dataE.result = aluout;
		end
	end
	
	assign dataE.writedata = writedata;
	assign dataE.csr = ereg.dataD.csr;
	assign dataE.pcplus4 = ereg.dataD.pc + 4;
	assign dataE.writereg = ereg.dataD.writereg;



	assign mreg.dataE_nxt = dataE;
	assign hazard.dataE = dataE;
	assign forward.instrE = ereg.dataD.instr;

	always_ff @(posedge clk) begin
		if(~reset && (dataE.instr.ctl.regwrite | dataE.instr.ctl.memwrite)) begin
			// $display("pc %x, alufunc %x, a %x, b %x, c %x", ereg.dataD.pc, ereg.dataD.instr.ctl.alufunc, alusrca, alusrcb, dataE.result);
		end
	end
	
endmodule


`endif
