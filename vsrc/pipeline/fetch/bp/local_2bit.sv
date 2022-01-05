`ifndef __LOCAL_2BIT_SV
`define __LOCAL_2BIT_SV

`ifdef VERILATOR
`include "ram/LUTRAM_DualPort.sv"
`else

`endif

module local_2bit
	import common::*;
	#(
	parameter FETCH_WIDTH = 4
)(
	input logic clk, reset,

	/* Read: FETCH_WIDTH items */
	input u64 pcF,
	output logic [FETCH_WIDTH-1:0] pred_taken,

	/* Update: 1 item */
	input u64 pc_update,
	input u1 valid,
	input u1 taken
);

	localparam HIS_WIDTH = 1;
	localparam ADDR_WIDTH = 16 - 2 - 2 + HIS_WIDTH;
	localparam type addr_t = logic[ADDR_WIDTH-1:0];

	localparam STRONG_TAKEN = 2'b01;
	localparam WEAK_TAKEN = 2'b00;
	localparam STRONG_NOT_TAKEN = 2'b10;
	localparam WEAK_NOT_TAKEN = 2'b11;

	if (FETCH_WIDTH == 4) begin

		for (genvar i = 0; i < FETCH_WIDTH; i++) begin
			u1 strobe;
			assign strobe = valid && pc_update[4:3] == i[1:0];
			logic [HIS_WIDTH-1:0] his_read, his_update, his_nxt;
			u2 cnt_read, cnt_update, cnt_nxt;
			if (HIS_WIDTH < 2) assign his_nxt = taken;
			else 
			assign his_nxt = {his_update[HIS_WIDTH-2:0], taken};
			assign pred_taken[i] = cnt_read == STRONG_TAKEN || cnt_read == WEAK_TAKEN;

			LUTRAM_DualPort #(
				.ADDR_WIDTH(ADDR_WIDTH - HIS_WIDTH),
				.DATA_WIDTH(HIS_WIDTH),
				.BYTE_WIDTH(HIS_WIDTH),
				.READ_LATENCY(0)
			) hist_ram (
				.clk(clk),
				.en_1(1'b1),
				.en_2(1'b1),

				.addr_1(pc_update[15:4]), // update
				.addr_2(pcF[15:4]), // read
				.strobe(strobe),
				.wdata(his_nxt),
				.rdata_1(his_update),
				.rdata_2(his_read)
			);

			LUTRAM_DualPort #(
				.ADDR_WIDTH(ADDR_WIDTH),
				.DATA_WIDTH(2),
				.BYTE_WIDTH(2),
				.READ_LATENCY(0)
			) bit2_ram (
				.clk(clk),
				.en_1(1'b1),
				.en_2(1'b1),

				.addr_1({his_update, pc_update[15:4]}), // update
				.addr_2({his_read, pcF[15:4]}), // read
				.strobe(strobe),
				.wdata(cnt_nxt),
				.rdata_1(cnt_update),
				.rdata_2(cnt_read)
			);

			always_comb begin
				cnt_nxt = 'x;
				unique case(cnt_update)
					STRONG_TAKEN: begin
						if (taken) cnt_nxt = STRONG_TAKEN;
						else cnt_nxt = WEAK_TAKEN;
					end
					WEAK_TAKEN: begin
						if (taken) cnt_nxt = STRONG_TAKEN;
						else cnt_nxt = WEAK_NOT_TAKEN;
					end
					STRONG_NOT_TAKEN: begin
						if (taken) cnt_nxt = WEAK_NOT_TAKEN;
						else cnt_nxt = STRONG_NOT_TAKEN;
					end
					WEAK_NOT_TAKEN: begin
						if (taken) cnt_nxt = WEAK_TAKEN;
						else cnt_nxt = STRONG_NOT_TAKEN;
					end
					default: begin
						
					end
				endcase
			end
		end
	end else begin
		
	end

endmodule


`endif
