`ifndef CONFIG_SV
`define CONFIG_SV

package config_pkg;
	// parameters
	parameter AREG_READ_PORTS = 1;
	parameter AREG_WRITE_PORTS = 1;
	parameter USE_CACHE = 1'b1;
	parameter USE_ICACHE = USE_CACHE;
	parameter USE_DCACHE = USE_CACHE;
	parameter ADD_LATENCY = 1'b0;
	parameter AXI_BURST_NUM = 32;
endpackage

`endif