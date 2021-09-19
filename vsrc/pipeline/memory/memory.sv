`ifndef __MEMORY_SV
`define __MEMORY_SV


`include "include/interface.svh"
`include "pipeline/memory/writedata.sv"

module memory
	import common::*;
	import memory_pkg::*;
	// import exception_pkg::*;
	(
	mreg_intf.memory mreg,
	wreg_intf.memory wreg,
	hazard_intf.memory hazard,
	forward_intf.memory forward,
	// exception_intf.memory exception,
	output mread_req mread,
	output mwrite_req mwrite/* verilator split_var */,
	input word_t rd

);
	assign mread.valid = mreg.dataE.instr.ctl.memread;
	assign mread.addr = mreg.dataE.result;
	assign mread.size = mreg.dataE.instr.ctl.msize;

	assign mwrite.valid = mreg.dataE.instr.ctl.memwrite;
	assign mwrite.addr = mreg.dataE.result;

	writedata writedata(
		.addr(mwrite.addr[2:0]), 
		._wd(mreg.dataE.writedata), 
		.msize(mreg.dataE.instr.ctl.msize), 
		.wd(mwrite.data),
		.strobe(mwrite.strobe)
	);
	assign mwrite.size = mreg.dataE.instr.ctl.msize;

	memory_data_t dataM;
	assign dataM.instr = mreg.dataE.instr;
	assign dataM.rd = rd;
	assign dataM.result = mreg.dataE.instr.ctl.csrwrite ? mreg.dataE.csr : mreg.dataE.result;
	assign dataM.writereg = mreg.dataE.writereg;
	assign dataM.pcplus4 = mreg.dataE.pcplus4;
	// assign dataM.csr = mreg.dataE.result;
	always_comb begin
		dataM.csr = 'x;
		unique case(dataM.instr.ctl.csr_write_type)
			CSR_CSRRC: begin
				dataM.csr = mreg.dataE.csr & ~mreg.dataE.result;
			end
			CSR_CSRRW: begin
				dataM.csr = mreg.dataE.result;
			end
			CSR_CSRRS: begin
				dataM.csr = mreg.dataE.csr | mreg.dataE.result;
			end
			default: begin
				
			end
		endcase
	end
	

	assign wreg.dataM_nxt = dataM;
	assign forward.dataM = dataM;
	assign hazard.dataM = dataM;

endmodule



`endif