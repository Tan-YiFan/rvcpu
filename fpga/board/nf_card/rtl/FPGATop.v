`include "axi.vh"

module FPGATop (
  input clock,
  input reset,
  `axi_master_if(io_mem, 64, 8)
);
  wire [39:0] cpu_mem_awaddr;
  wire [39:0] cpu_mem_araddr;
  assign io_mem_awaddr = cpu_mem_awaddr[39:31] == 9'h1 ? {9'h90, cpu_mem_awaddr[30:0]} : cpu_mem_awaddr;
  assign io_mem_araddr = cpu_mem_araddr[39:31] == 9'h1 ? {9'h90, cpu_mem_araddr[30:0]} : cpu_mem_araddr;

  SimTop sim_top(
    .clock(clock),
    .reset(reset),
    .io_mem_awready(io_mem_awready),
    .io_mem_awvalid(io_mem_awvalid),
    .io_mem_awaddr(cpu_mem_awaddr), // mem_awaddr[39:32] = 0
    .io_mem_awprot(io_mem_awprot),
    .io_mem_awid(io_mem_awid),
    .io_mem_awuser(io_mem_awuser),
    .io_mem_awlen(io_mem_awlen),
    .io_mem_awsize(io_mem_awsize),
    .io_mem_awburst(io_mem_awburst),
    .io_mem_awlock(io_mem_awlock),
    .io_mem_awcache(io_mem_awcache),
    .io_mem_awqos(io_mem_awqos),
    .io_mem_wready(io_mem_wready),
    .io_mem_wvalid(io_mem_wvalid),
    .io_mem_wdata(io_mem_wdata),
    .io_mem_wstrb(io_mem_wstrb),
    .io_mem_wlast(io_mem_wlast),
    .io_mem_bready(io_mem_bready),
    .io_mem_bvalid(io_mem_bvalid),
    .io_mem_bresp(io_mem_bresp),
    .io_mem_bid(io_mem_bid),
    .io_mem_buser(io_mem_buser),
    .io_mem_arready(io_mem_arready),
    .io_mem_arvalid(io_mem_arvalid),
    .io_mem_araddr(cpu_mem_araddr), // mem_araddr[39:32] = 0
    .io_mem_arprot(io_mem_arprot),
    .io_mem_arid(io_mem_arid),
    .io_mem_aruser(io_mem_aruser),
    .io_mem_arlen(io_mem_arlen),
    .io_mem_arsize(io_mem_arsize),
    .io_mem_arburst(io_mem_arburst),
    .io_mem_arlock(io_mem_arlock),
    .io_mem_arcache(io_mem_arcache),
    .io_mem_arqos(io_mem_arqos),
    .io_mem_rready(io_mem_rready),
    .io_mem_rvalid(io_mem_rvalid),
    .io_mem_rresp(io_mem_rresp),
    .io_mem_rdata(io_mem_rdata),
    .io_mem_rlast(io_mem_rlast),
    .io_mem_rid(io_mem_rid),
    .io_mem_ruser(io_mem_ruser)
  );

endmodule
