`ifndef __MUL_IQUEUE_SV
`define __MUL_IQUEUE_SV

`ifdef VERILATOR

`endif

module mul_iqueue
	import common::*;
	import issue_pkg::*;
	import decode_pkg::*;#(
	parameter QLEN = 4,

	localparam type iq_addr_t = logic[$clog2(QLEN)-1:0]
)(
	input logic clk, reset, wen, stall,
	input write_req_t [FETCH_WIDTH-1:0] write,
	input wake_req_t [WAKE_NUM-1:0] wake,
	input wake_req_t [COMMIT_WIDTH-1:0] retire,
	// input u1[WAKE_NUM-1:0] wake,
	// input word_t wake_data[WAKE_NUM-1:0],
	output read_resp_t read,

	output logic full
);
	br_iqueue #(.QLEN(QLEN)) iqueue_inst (
		.*
	);
endmodule

`endif
