`timescale 1ns / 1ns

module scalar_sync #(parameter STAGES = 2)(
    input clk_dst,
    input src,
    output dst
);
    reg [STAGES-1:0] shift;
    always @(posedge clk_dst) begin
        shift <= {shift[STAGES-2:0], src};
    end
    assign dst = shift[STAGES-1];
endmodule

module arm_clock_counter (
    input           cnt_clk,
    input           cnt_resetn,
    input           s_axi_aclk,
    input           s_axi_aresetn,
    input           s_axi_arvalid,
    output          s_axi_arready,
    input   [11:0]  s_axi_araddr,
    input   [2 :0]  s_axi_arprot,
    output          s_axi_rvalid,
    input           s_axi_rready,
    output  [1 :0]  s_axi_rresp,
    output  [63:0]  s_axi_rdata,
    input           s_axi_awvalid,
    output          s_axi_awready,
    input   [11:0]  s_axi_awaddr,
    input   [2 :0]  s_axi_awprot,
    input           s_axi_wvalid,
    output          s_axi_wready,
    input   [63:0]  s_axi_wdata,
    input   [7 :0]  s_axi_wstrb,
    output          s_axi_bvalid,
    input           s_axi_bready,
    output  [1 :0]  s_axi_bresp
);

    reg [63:0] cnt_r;

    always @(posedge cnt_clk) begin
        if (!cnt_resetn) cnt_r <= 64'd0;
        else cnt_r <= cnt_r + 64'd1;
    end

    // axi stuff

    wire ar_fire = s_axi_arvalid && s_axi_arready;
    wire r_fire = s_axi_rvalid && s_axi_rready;
    wire aw_fire = s_axi_awvalid && s_axi_awready;
    wire w_fire = s_axi_wvalid && s_axi_wready;
    wire b_fire = s_axi_bvalid && s_axi_bready;

    reg r_inflight, w_inflight;

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) r_inflight <= 1'b0;
        else r_inflight <= r_inflight ^ ar_fire ^ r_fire;
    end

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) w_inflight <= 1'b0;
        else w_inflight <= w_inflight ^ aw_fire ^ b_fire;
    end

    assign s_axi_arready = !r_inflight;
    assign s_axi_awready = !w_inflight;

    // read over axi

    // clock domains: aclk(A) cnt_clk(C)

    reg data_req, data_ack; // A, C
    reg [63:0] data_a, data_c; // A, C
    wire data_req_c, data_ack_a;

    scalar_sync u_req_sync(.clk_dst(cnt_clk),       .src(data_req),     .dst(data_req_c));
    scalar_sync u_ack_sync(.clk_dst(s_axi_aclk),    .src(data_ack),     .dst(data_ack_a));

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn)                 data_req <= 1'b0;
        else if (data_ack_a)                data_req <= 1'b0;
        else if (ar_fire)                   data_req <= 1'b1;
    end

    always @(posedge cnt_clk) begin
        if (!cnt_resetn)                        data_c <= 64'd0;
        else if (data_req_c && !data_ack)   data_c <= cnt_r;
    end

    always @(posedge cnt_clk) begin
        if (!cnt_resetn)                        data_ack <= 1'b0;
        else                                data_ack <= data_req_c;
    end

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn)                 data_a <= 64'd0;
        else if (data_ack_a && data_req)    data_a <= data_c;
    end

    reg [1:0] data_ack_a_scan;
    always @(posedge s_axi_aclk) begin
        data_ack_a_scan <= {data_ack_a_scan[0], data_ack_a};
    end

    reg rvalid_r;
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn)                 rvalid_r <= 1'b0;
        else if (r_fire)                    rvalid_r <= 1'b0;
        else if (data_ack_a_scan == 2'b10)  rvalid_r <= 1'b1;
    end

    assign s_axi_rvalid = rvalid_r;
    assign s_axi_rdata = data_a;
    assign s_axi_rresp = 2'd0;

    // ignore writes

    assign s_axi_wready = 1'b1;
    assign s_axi_bvalid = w_inflight;
    assign s_axi_bresp = 2'd0;

endmodule