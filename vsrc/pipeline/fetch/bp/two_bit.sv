`ifndef __TWO_BIT_SV
`define __TWO_BIT_SV

`ifdef VERILATOR

`endif

module two_bit #(

)(
	input logic clk, reset,

);

	if (FETCH_WIDTH == 4) begin
		
		for (genvar i = 0; i < 4; i++) begin
			
			RAM_SinglePort #(
				.ADDR_WIDTH(),
				.DATA_WIDTH(),
				.BYTE_WIDTH(),
				.MEM_TYPE(),
				.READ_LATENCY()
			) data_ram (
				.clk,  .en(1'b1),
				.addr(),
				.strobe(),
				.wdata(),
				.rdata()
			);
		end
		
	end else begin
		
	end

endmodule


`endif
