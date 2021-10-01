`ifndef CONFIG_SV
`define CONFIG_SV

package config_pkg;
	// parameters
	parameter AREG_READ_PORTS = 4;
	parameter AREG_WRITE_PORTS = 6;
	parameter USE_CACHE = 1'b1;
	parameter USE_ICACHE = USE_CACHE;
	parameter USE_DCACHE = USE_CACHE;
	parameter ADD_LATENCY = 1'b1;
	parameter AXI_BURST_NUM = 128;
	parameter ICACHE_BITS = 16;
	parameter DCACHE_BITS = 20;

	parameter FETCH_WIDTH = 4;
	parameter FETCH_STAGE = 1;

	parameter COMMIT_WIDTH = 4;

	parameter PREG_NUM = 64;
	
endpackage

`endif