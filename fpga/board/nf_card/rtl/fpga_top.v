`include "axi.vh"

module fpga_top (
  input clock,
  input reset,
  `axi_master_if(io_mem, 64, 8)
);
  wire [39:0] cpu_mem_awaddr;
  wire [39:0] cpu_mem_araddr;
  assign io_mem_awaddr = cpu_mem_awaddr[39:31] == 9'h1 ? {9'h90, cpu_mem_awaddr[30:0]} : cpu_mem_awaddr;
  assign io_mem_araddr = cpu_mem_araddr[39:31] == 9'h1 ? {9'h90, cpu_mem_araddr[30:0]} : cpu_mem_araddr;

  riscv_cpu_top cpu(
    .clock(clock),
    .reset(reset),
    .io_master_awready(io_mem_awready),
    .io_master_awvalid(io_mem_awvalid),
    .io_master_awaddr(cpu_mem_awaddr), // mem_awaddr[39:32] = 0
    .io_master_awprot(io_mem_awprot),
    .io_master_awid(io_mem_awid),
    .io_master_awuser(io_mem_awuser),
    .io_master_awlen(io_mem_awlen),
    .io_master_awsize(io_mem_awsize),
    .io_master_awburst(io_mem_awburst),
    .io_master_awlock(io_mem_awlock),
    .io_master_awcache(io_mem_awcache),
    .io_master_awqos(io_mem_awqos),
    .io_master_wready(io_mem_wready),
    .io_master_wvalid(io_mem_wvalid),
    .io_master_wdata(io_mem_wdata),
    .io_master_wstrb(io_mem_wstrb),
    .io_master_wlast(io_mem_wlast),
    .io_master_bready(io_mem_bready),
    .io_master_bvalid(io_mem_bvalid),
    .io_master_bresp(io_mem_bresp),
    .io_master_bid(io_mem_bid),
    .io_master_buser(io_mem_buser),
    .io_master_arready(io_mem_arready),
    .io_master_arvalid(io_mem_arvalid),
    .io_master_araddr(cpu_mem_araddr), // mem_araddr[39:32] = 0
    .io_master_arprot(io_mem_arprot),
    .io_master_arid(io_mem_arid),
    .io_master_aruser(io_mem_aruser),
    .io_master_arlen(io_mem_arlen),
    .io_master_arsize(io_mem_arsize),
    .io_master_arburst(io_mem_arburst),
    .io_master_arlock(io_mem_arlock),
    .io_master_arcache(io_mem_arcache),
    .io_master_arqos(io_mem_arqos),
    .io_master_rready(io_mem_rready),
    .io_master_rvalid(io_mem_rvalid),
    .io_master_rresp(io_mem_rresp),
    .io_master_rdata(io_mem_rdata),
    .io_master_rlast(io_mem_rlast),
    .io_master_rid(io_mem_rid),
    .io_master_ruser(io_mem_ruser),
    .io_interrupt()
  );

endmodule
