`ifndef __MEMORY_SV
`define __MEMORY_SV

`ifdef VERILATOR

`else

`endif

module memory 
	import common::*;#(
	parameter READ_WIDTH = 2,
	parameter WRITE_WIDTH = 2,
	parameter QLEN = 4
)(
	input logic clk, reset,
	input source_instr_t[2-1:0] srcs,
	output commit_instr_t[READ_WIDTH-1:0] read_commit,
	output commit_instr_t[WRITE_WIDTH-1:0] write_commit,
	output commit_instr_t[READ_WIDTH-1:0] uncached_commit,

	/* Write to WriteBuffer */
	output 

	/* Read Request */
	output dbus_req_t

	/* Reply from WriteBuffer */
	input 

	/* Reply from  DBus */


	/* Reply from WriteBuffer */


);

	localparam type mpipe12_t = struct packed {
		// each op
		u1 valid;
		u1 read, write;
		u64 addr;
		u64 data;
		preg_addr_t dst;
		msize_t msize;
	};

	localparam type mpipe23_t = struct packed {
		// read
		u1 valid;
		preg_addr_t dst;
		msize_t msize;
	};

	localparam type mpipe34_t = struct packed {
		// read

	};

	/* Stage 1: Address Generation,
			Byte Write Transformation and 
			(Batched 2W2R FIFO) or Pass-through,
			uncached commit */
	u1[1:0] is_uncached;
	u64[1:0] addr;
	u64[1:0] writedata;
	strobe_t [1:0] strobe;

	// Address Generation
	for (genvar i = 0; i < 2; i++) begin
		assign addr[i] = srcs[i].d1 + srcs[i].imm;
	end

	// Byte Write Transformation
	for (genvar i = 0; i < 2; i++) begin
		writedata wd_inst (
			.addr(addr[i][2:0]),
			._wd(srcs[i].d2),
			.msize(srcs[i].ctl.msize),
			.wd(writedata[i]),
			.strobe(strobe[i])
		);
	end
	
	// check uncached
	for (genvar i = 0; i < 2; i++) begin
		assign is_uncached[i] = ~srcs[i].d1[31];
	end

	// Stage 1->2 Pipeline / uncached commit
	for (genvar i = 0; i < 2; i++) begin
		// Pipe

		// uncached commit
		assign uncached_commit[i].valid = srcs[i].valid & is_uncached[i];
		assign uncached_commit[i].data = writedata[i];
		assign uncached_commit[i].extra = 'x;
		assign uncached_commit[i].dst = srcs[i].dst;
	end
	
	

	/* Stage 2.W: Write to WriteBuffer */

	for (genvar i = 0; i < WRITE_WIDTH; i++) begin
		assign write_commit[i].valid = 
		assign write_commit[i].data = 
		assign write_commit[i].extra = 'x;
		assign write_commit[i].dst = 
	end
	

	/* Stage 2.R: DCache Request and WriteBuffer (or from Instr I) Fetch */

	/* Stage 3.R: DCache Response passing FF */

	/* Stage 4.R: DCache Response, Merge WriteBuffer and Handle ByteWrite */

	for (genvar i = 0; i < READ_WIDTH; i++) begin
		assign read_commit[i].valid = 
		assign read_commit[i].data = 
		assign read_commit[i].extra = 'x;
		assign read_commit[i].dst = 
	end
	
endmodule


// `if 0
// `ifdef VERILATOR
// `include "include/interface.svh"
// `include "pipeline/memory/writedata.sv"

// `else
// `include "interface.svh"
// `endif
// module memory
// 	import common::*;
// 	import memory_pkg::*;
// 	// import exception_pkg::*;
// 	(
// 	mreg_intf.memory mreg,
// 	wreg_intf.memory wreg,
// 	hazard_intf.memory hazard,
// 	forward_intf.memory forward,
// 	// exception_intf.memory exception,
// 	output mread_req mread,
// 	/* verilator lint_off UNOPTFLAT */
// 	output mwrite_req mwrite,
// 	input word_t rd

// );
// 	assign mread.valid = mreg.dataE.instr.ctl.memread;
// 	assign mread.addr = mreg.dataE.result;
// 	assign mread.size = mreg.dataE.instr.ctl.msize;

// 	assign mwrite.valid = mreg.dataE.instr.ctl.memwrite;
// 	assign mwrite.addr = mreg.dataE.result;

// 	writedata writedata(
// 		.addr(mwrite.addr[2:0]), 
// 		._wd(mreg.dataE.writedata), 
// 		.msize(mreg.dataE.instr.ctl.msize), 
// 		.wd(mwrite.data),
// 		.strobe(mwrite.strobe)
// 	);
// 	assign mwrite.size = mreg.dataE.instr.ctl.msize;

// 	memory_data_t dataM;
// 	assign dataM.instr = mreg.dataE.instr;
// 	assign dataM.rd = rd;
// 	assign dataM.result = mreg.dataE.instr.ctl.csrwrite ? mreg.dataE.csr : mreg.dataE.result;
// 	assign dataM.writereg = mreg.dataE.writereg;
// 	assign dataM.pcplus4 = mreg.dataE.pcplus4;
// 	// assign dataM.csr = mreg.dataE.result;
// 	always_comb begin
// 		dataM.csr = 'x;
// 		if (mreg.dataE.instr.ctl.csrwrite) unique case(mreg.dataE.instr.ctl.csr_write_type)
// 			CSR_CSRRC: begin
// 				dataM.csr = mreg.dataE.csr & ~mreg.dataE.result;
// 			end
// 			CSR_CSRRW: begin
// 				dataM.csr = mreg.dataE.result;
// 			end
// 			CSR_CSRRS: begin
// 				dataM.csr = mreg.dataE.csr | mreg.dataE.result;
// 			end
// 			default: begin
				
// 			end
// 		endcase
// 	end
	

// 	assign wreg.dataM_nxt = dataM;
// 	assign forward.dataM = dataM;
// 	assign hazard.dataM = dataM;

// endmodule



// `endif
`endif