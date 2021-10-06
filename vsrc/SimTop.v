
`include "defines.sv"
`ifdef VERILATOR
`include "mycpu_top.sv"
`endif
`define AXI_TOP_INTERFACE(name) io_memAXI_0_``name

module SimTop(
    input                               clock,
    input                               reset,

    input  [63:0]                       io_logCtrl_log_begin,
    input  [63:0]                       io_logCtrl_log_end,
    input  [63:0]                       io_logCtrl_log_level,
    input                               io_perfInfo_clean,
    input                               io_perfInfo_dump,

    output                              io_uart_out_valid,
    output [7:0]                        io_uart_out_ch,
    output                              io_uart_in_valid,
    input  [7:0]                        io_uart_in_ch,

    input                               `AXI_TOP_INTERFACE(aw_ready),
    output                              `AXI_TOP_INTERFACE(aw_valid),
    output [`AXI_ADDR_WIDTH-1:0]        `AXI_TOP_INTERFACE(aw_bits_addr),
    output [2:0]                        `AXI_TOP_INTERFACE(aw_bits_prot),
    output [`AXI_ID_WIDTH-1:0]          `AXI_TOP_INTERFACE(aw_bits_id),
    output [`AXI_USER_WIDTH-1:0]        `AXI_TOP_INTERFACE(aw_bits_user),
    output [7:0]                        `AXI_TOP_INTERFACE(aw_bits_len),
    output [2:0]                        `AXI_TOP_INTERFACE(aw_bits_size),
    output [1:0]                        `AXI_TOP_INTERFACE(aw_bits_burst),
    output                              `AXI_TOP_INTERFACE(aw_bits_lock),
    output [3:0]                        `AXI_TOP_INTERFACE(aw_bits_cache),
    output [3:0]                        `AXI_TOP_INTERFACE(aw_bits_qos),
    
    input                               `AXI_TOP_INTERFACE(w_ready),
    output                              `AXI_TOP_INTERFACE(w_valid),
    output [`AXI_DATA_WIDTH-1:0]        `AXI_TOP_INTERFACE(w_bits_data)         [3:0],
    output [`AXI_DATA_WIDTH/8-1:0]      `AXI_TOP_INTERFACE(w_bits_strb),
    output                              `AXI_TOP_INTERFACE(w_bits_last),
    
    output                              `AXI_TOP_INTERFACE(b_ready),
    input                               `AXI_TOP_INTERFACE(b_valid),
    input  [1:0]                        `AXI_TOP_INTERFACE(b_bits_resp),
    input  [`AXI_ID_WIDTH-1:0]          `AXI_TOP_INTERFACE(b_bits_id),
    input  [`AXI_USER_WIDTH-1:0]        `AXI_TOP_INTERFACE(b_bits_user),

    input                               `AXI_TOP_INTERFACE(ar_ready),
    output                              `AXI_TOP_INTERFACE(ar_valid),
    output [`AXI_ADDR_WIDTH-1:0]        `AXI_TOP_INTERFACE(ar_bits_addr),
    output [2:0]                        `AXI_TOP_INTERFACE(ar_bits_prot),
    output [`AXI_ID_WIDTH-1:0]          `AXI_TOP_INTERFACE(ar_bits_id),
    output [`AXI_USER_WIDTH-1:0]        `AXI_TOP_INTERFACE(ar_bits_user),
    output [7:0]                        `AXI_TOP_INTERFACE(ar_bits_len),
    output [2:0]                        `AXI_TOP_INTERFACE(ar_bits_size),
    output [1:0]                        `AXI_TOP_INTERFACE(ar_bits_burst),
    output                              `AXI_TOP_INTERFACE(ar_bits_lock),
    output [3:0]                        `AXI_TOP_INTERFACE(ar_bits_cache),
    output [3:0]                        `AXI_TOP_INTERFACE(ar_bits_qos),
    
    output                              `AXI_TOP_INTERFACE(r_ready),
    input                               `AXI_TOP_INTERFACE(r_valid),
    input  [1:0]                        `AXI_TOP_INTERFACE(r_bits_resp),
    input  [`AXI_DATA_WIDTH-1:0]        `AXI_TOP_INTERFACE(r_bits_data)         [3:0],
    input                               `AXI_TOP_INTERFACE(r_bits_last),
    input  [`AXI_ID_WIDTH-1:0]          `AXI_TOP_INTERFACE(r_bits_id),
    input  [`AXI_USER_WIDTH-1:0]        `AXI_TOP_INTERFACE(r_bits_user)
);

    wire awready;
    wire awvalid;
    wire [`AXI_ADDR_WIDTH-1:0] awaddr;
    wire [2:0] awprot;
    wire [`AXI_ID_WIDTH-1:0] awid;
    wire [`AXI_USER_WIDTH-1:0] awuser;
    wire [7:0] awlen;
    wire [2:0] awsize;
    wire [1:0] awburst;
    wire awlock;
    wire [3:0] awcache;
    wire [3:0] awqos;
    wire [3:0] awregion;

    wire wready;
    wire wvalid;
    wire [`AXI_DATA_WIDTH-1:0] wdata;
    wire [`AXI_DATA_WIDTH/8-1:0] wstrb;
    wire wlast;
    wire [`AXI_USER_WIDTH-1:0] wuser;
    
    wire bready;
    wire bvalid;
    wire [1:0] bresp;
    wire [`AXI_ID_WIDTH-1:0] bid;
    wire [`AXI_USER_WIDTH-1:0] buser;

    wire arready;
    wire arvalid;
    wire [`AXI_ADDR_WIDTH-1:0] araddr;
    wire [2:0] arprot;
    wire [`AXI_ID_WIDTH-1:0] arid;
    wire [`AXI_USER_WIDTH-1:0] aruser;
    wire [7:0] arlen;
    wire [2:0] arsize;
    wire [1:0] arburst;
    wire arlock;
    wire [3:0] arcache;
    wire [3:0] arqos;
    wire [3:0] arregion;
    
    wire rready;
    wire rvalid;
    wire [1:0] rresp;
    wire [`AXI_DATA_WIDTH-1:0] rdata;
    wire rlast;
    wire [`AXI_ID_WIDTH-1:0] rid;
    wire [`AXI_USER_WIDTH-1:0] ruser;

    assign arready                                 = `AXI_TOP_INTERFACE(ar_ready);
    assign `AXI_TOP_INTERFACE(ar_valid)             = arvalid;
    assign `AXI_TOP_INTERFACE(ar_bits_addr)         = araddr;
    assign `AXI_TOP_INTERFACE(ar_bits_prot)         = arprot;
    assign `AXI_TOP_INTERFACE(ar_bits_id)           = arid;
    assign `AXI_TOP_INTERFACE(ar_bits_user)         = aruser;
    assign `AXI_TOP_INTERFACE(ar_bits_len)          = arlen;
    assign `AXI_TOP_INTERFACE(ar_bits_size)         = arsize;
    assign `AXI_TOP_INTERFACE(ar_bits_burst)        = arburst;
    assign `AXI_TOP_INTERFACE(ar_bits_lock)         = arlock;
    assign `AXI_TOP_INTERFACE(ar_bits_cache)        = arcache;
    assign `AXI_TOP_INTERFACE(ar_bits_qos)          = arqos;
    
    assign `AXI_TOP_INTERFACE(r_ready)              = rready;
    assign rvalid                                  = `AXI_TOP_INTERFACE(r_valid);
    assign rresp                                   = `AXI_TOP_INTERFACE(r_bits_resp);
    assign rdata                                   = `AXI_TOP_INTERFACE(r_bits_data)[0];
    assign rlast                                   = `AXI_TOP_INTERFACE(r_bits_last);
    assign rid                                     = `AXI_TOP_INTERFACE(r_bits_id);
    assign ruser                                   = `AXI_TOP_INTERFACE(r_bits_user);

    assign `AXI_TOP_INTERFACE(b_ready) = bready;
    assign bvalid = `AXI_TOP_INTERFACE(b_valid);
    assign bresp = `AXI_TOP_INTERFACE(b_bits_resp);
    assign bid = `AXI_TOP_INTERFACE(b_bits_id);
    assign buser = `AXI_TOP_INTERFACE(b_bits_user);

    assign wready = `AXI_TOP_INTERFACE(w_ready);
    assign `AXI_TOP_INTERFACE(w_valid) = wvalid;
    assign `AXI_TOP_INTERFACE(w_bits_data)[0] = wdata;
    assign `AXI_TOP_INTERFACE(w_bits_strb) = wstrb;
    assign `AXI_TOP_INTERFACE(w_bits_last) = wlast;

    assign awready = `AXI_TOP_INTERFACE(aw_ready);
    assign `AXI_TOP_INTERFACE(aw_valid) = awvalid;
    assign `AXI_TOP_INTERFACE(aw_bits_addr) = awaddr;
    assign `AXI_TOP_INTERFACE(aw_bits_prot) = awprot;
    assign `AXI_TOP_INTERFACE(aw_bits_id) = awid;
    assign `AXI_TOP_INTERFACE(aw_bits_user) = awuser;
    assign `AXI_TOP_INTERFACE(aw_bits_len) = awlen;
    assign `AXI_TOP_INTERFACE(aw_bits_size) = awsize;
    assign `AXI_TOP_INTERFACE(aw_bits_burst) = awburst;
    assign `AXI_TOP_INTERFACE(aw_bits_lock) = awlock;
    assign `AXI_TOP_INTERFACE(aw_bits_cache) = awcache;
    assign `AXI_TOP_INTERFACE(aw_bits_qos) = awqos;



mycpu_top ucpu_top(
    .aclk(clock), .areset(reset),
    .*
);


/*     axi_rw u_axi_rw (
        .clock                          (clock),
        .reset                          (reset),

        .rw_valid_i                     (if_valid),
        .rw_ready_o                     (if_ready),
        .rw_req_i                       (req),
        .data_read_o                    (if_data_read),
        .data_write_i                   (data_write),
        .rw_addr_i                      (if_addr),
        .rw_size_i                      (if_size),
        .rw_resp_o                      (if_resp),

        .axi_aw_ready_i                 (aw_ready),
        .axi_aw_valid_o                 (aw_valid),
        .axi_aw_addr_o                  (aw_addr),
        .axi_aw_prot_o                  (aw_prot),
        .axi_aw_id_o                    (aw_id),
        .axi_aw_user_o                  (aw_user),
        .axi_aw_len_o                   (aw_len),
        .axi_aw_size_o                  (aw_size),
        .axi_aw_burst_o                 (aw_burst),
        .axi_aw_lock_o                  (aw_lock),
        .axi_aw_cache_o                 (aw_cache),
        .axi_aw_qos_o                   (aw_qos),
        .axi_aw_region_o                (aw_region),

        .axi_w_ready_i                  (w_ready),
        .axi_w_valid_o                  (w_valid),
        .axi_w_data_o                   (w_data),
        .axi_w_strb_o                   (w_strb),
        .axi_w_last_o                   (w_last),
        .axi_w_user_o                   (w_user),
        
        .axi_b_ready_o                  (b_ready),
        .axi_b_valid_i                  (b_valid),
        .axi_b_resp_i                   (b_resp),
        .axi_b_id_i                     (b_id),
        .axi_b_user_i                   (b_user),

        .axi_ar_ready_i                 (ar_ready),
        .axi_ar_valid_o                 (ar_valid),
        .axi_ar_addr_o                  (ar_addr),
        .axi_ar_prot_o                  (ar_prot),
        .axi_ar_id_o                    (ar_id),
        .axi_ar_user_o                  (ar_user),
        .axi_ar_len_o                   (ar_len),
        .axi_ar_size_o                  (ar_size),
        .axi_ar_burst_o                 (ar_burst),
        .axi_ar_lock_o                  (ar_lock),
        .axi_ar_cache_o                 (ar_cache),
        .axi_ar_qos_o                   (ar_qos),
        .axi_ar_region_o                (ar_region),
        
        .axi_r_ready_o                  (r_ready),
        .axi_r_valid_i                  (r_valid),
        .axi_r_resp_i                   (r_resp),
        .axi_r_data_i                   (r_data),
        .axi_r_last_i                   (r_last),
        .axi_r_id_i                     (r_id),
        .axi_r_user_i                   (r_user)
    );

    wire if_valid;
    wire if_ready;
    wire req = `REQ_READ;
    wire [63:0] if_data_read;
    wire [63:0] data_write;
    wire [63:0] if_addr;
    wire [1:0] if_size;
    wire [1:0] if_resp;

    cpu u_cpu(
        .clock                          (clock),
        .reset                          (reset),

        .if_valid                       (if_valid),
        .if_ready                       (if_ready),
        .if_data_read                   (if_data_read),
        .if_addr                        (if_addr),
        .if_size                        (if_size),
        .if_resp                        (if_resp)
    ); */


endmodule