`ifndef __FORWARD_PKG_SV
`define __FORWARD_PKG_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif
import common::*;

package forward_pkg;
	typedef enum logic[1:0] {
		NOFORWARD,
		FORWARDM,
		FORWARDW
	} forward_t;
	
endpackage

`endif
