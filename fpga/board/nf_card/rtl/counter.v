`timescale 1ns / 1ns

module arm_clock_counter (
  input cnt_clk,
  input cnt_resetn,
  output reg [31:0] cnt_output
);

  reg [31:0] cnt_r;

  always @(posedge cnt_clk) begin
    if (!cnt_resetn) begin
      cnt_r <= 32'b0;
      cnt_output <= 32'b0;
    end else if (cnt_r == 32'd1000) begin
      cnt_output <= cnt_output + 32'b1;
      cnt_r <= 32'b0;
    end else begin
      cnt_r <= cnt_r + 1;
    end
  end
endmodule
