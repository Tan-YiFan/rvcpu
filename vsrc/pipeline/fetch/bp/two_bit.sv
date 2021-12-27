`ifndef __TWO_BIT_SV
`define __TWO_BIT_SV

`ifdef VERILATOR

`endif

module two_bit #(

)(
	input logic clk, reset,

);
	localparam ADDR_WIDTH = 16 - 2 - 2;
	localparam type addr_t = logic[ADDR_WIDTH-1:0];

	if (FETCH_WIDTH == 4) begin
		for (genvar i = 0; i < 4; i++) begin
			addr_t addr_f, addr_up;
			u2 rdata_f, rdata_up;
			u1 strobe;
			LUTRAM_DualPort #(
				.ADDR_WIDTH(ADDR_WIDTH),
				.DATA_WIDTH(2),
				.BYTE_WIDTH(2),
				.READ_LATENCY(0)
			)(
				.clk(clk),
				.en_1(1'b1),
				.en_2(1'b1),

				.addr_1(addr_up),
				.addr_2(addr_f),
				.strobe(strobe),
				.wdata(wdata),
				.rdata_1(rdata_up),
				.rdata_2(rdata_f)
			);
			always_comb begin
				wdata = 'x;
				if (strobe) begin
					unique case(rdata_up)
						2'b00: begin
							
						end
						2'b01: begin
							
						end
						2'b10: begin
							
						end
						2'b11: begin
							
						end
						default: begin
							
						end
					endcase
				end
			end
			assign strobe = 'x;
		end
		
	end else begin
		
	end

endmodule


`endif
