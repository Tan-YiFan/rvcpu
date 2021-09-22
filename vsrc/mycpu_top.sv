`ifdef VERILATOR
`include "include/common.sv"
`include "util/CBusToAXI.sv"
`include "util/CBusToSRAM.sv"
`endif
module mycpu_top
	import common::*;(
	input logic aclk, areset,
`ifdef VERILATOR
	output                              io_uart_out_valid,
    output [7:0]                        io_uart_out_ch,
`endif

	output logic [3 :0] arid,
	output logic [63:0] araddr,
	output logic [7 :0] arlen,
	output logic [2 :0] arsize,
	output logic [1 :0] arburst,
	output logic arlock,
	output logic [3 :0] arcache,
	output logic [2 :0] arprot,
	output logic        arvalid,
	input  logic        arready,
	input  logic [3 :0] rid,
	input  logic [63:0] rdata,
	input  logic [1 :0] rresp,
	input  logic        rlast,
	input  logic        rvalid,
	output logic        rready,
	output logic [3 :0] awid,
	output logic [63:0] awaddr,
	output logic [7 :0] awlen,
	output logic [2 :0] awsize,
	output logic [1 :0] awburst,
	output logic  awlock,
	output logic [3 :0] awcache,
	output logic [2 :0] awprot,
	output logic        awvalid,
	input  logic        awready,
	output logic [63:0] wdata,
	output logic [7 :0] wstrb,
	output logic        wlast,
	output logic        wvalid,
	input  logic        wready,
	input  logic [3 :0] bid,
	input  logic [1 :0] bresp,
	input  logic        bvalid,
	output logic        bready
);
	cbus_req_t  oreq;
	cbus_resp_t oresp;

	VTop top(.clk(aclk), .reset(areset), .*);
`ifndef VERILATOR
	CBusToAXI cvt(.creq(oreq), .cresp(oresp), .*);
`else
	u64 rIdx;
	u64 rdata1;
	u64 wIdx;
	u64 wdata1;
	u64 wmask;
	logic wen;
	logic en;

	CBusToSRAM CBusToSRAM(.clk(aclk), .reset(areset), .rdata(rdata1), .wdata(wdata1), .*);
	RAMHelper RAMHelper(.clk(aclk), .rdata(rdata1), .wdata(wdata1), .*);
	assign io_uart_out_valid = oreq.valid && oreq.addr == 64'h40600004 && oreq.is_write;
	assign io_uart_out_ch = oreq.data[39-:8];
	
	// u64 bit_wen;
	// for (genvar i = 0; i < 8; i++) begin
	// 	assign bit_wen[i * 8 + 7 -: 8] = {8{oreq.strobe[i]}};
	// end
	
	// RAMHelper RAMHelper (
	// .clk(aclk),
	// .rIdx({38'b0, oreq.addr[28:3]}), // 0 -> 0, 8 -> 1
	// .rdata(oresp.data),
	// .wIdx({38'b0, oreq.addr[28:3]}),
	// .wdata(oreq.data),
	// .wmask(bit_wen),
	// .wen(oreq.addr[31]),
	// .en(oreq.valid && oreq.addr[31])
    //   );
    //   assign oresp.last = 1'b1;
    //   assign oresp.ready = 1'b1;

      always_ff @(posedge aclk) begin
	      if(0)
			$display("hazard flush %x, %x, %x %x, stall %x %x %x %x", 
			top.core.hazard_intf.flushD,
			top.core.hazard_intf.flushE,
			top.core.hazard_intf.flushM,
			top.core.hazard_intf.flushW,
			top.core.hazard_intf.stallF,
			top.core.hazard_intf.stallD,
			top.core.hazard_intf.stallE,
			top.core.hazard_intf.stallM);
      end
      
      
`endif
	
endmodule