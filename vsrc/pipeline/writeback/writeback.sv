`ifndef __WRITEBACK_SV
`define __WRITEBACK_SV

`ifdef VERILATOR
`include "include/interface.svh"
`include "pipeline/memory/readdata.sv"

`else
`include "interface.svh"
`endif
module writeback
    import common::*;
    import writeback_pkg::*;
    import decode_pkg::*; (
    wreg_intf.writeback wreg,
    regfile_intf.writeback regfile,
    hazard_intf.writeback hazard,
    forward_intf.writeback forward,
    csr_intf.writeback csr
    
    // debug
//     output word_t pc
);
    word_t pc;
    assign pc = wreg.dataM.pcplus4;
    word_t result;
    word_t readdataW;
    readdata readdata(
        ._rd(wreg.dataM.rd),
        .msize(wreg.dataM.instr.ctl.msize),
        .addr(wreg.dataM.result[2:0]),
	.mem_unsigned(wreg.dataM.instr.ctl.mem_unsigned),
        .rd(readdataW)
    );
    assign result = wreg.dataM.instr.ctl.memread ? 
                    readdataW : wreg.dataM.result;
    assign regfile.valid = wreg.dataM.instr.ctl.regwrite;
    assign regfile.wa = wreg.dataM.writereg;
    assign regfile.wd = result;
    
    writeback_data_t dataW;
    assign dataW.instr = wreg.dataM.instr;
    assign dataW.writereg = wreg.dataM.writereg;
    assign dataW.result = result;
    assign forward.dataW = dataW;

    assign hazard.dataW = dataW;
    assign csr.valid = wreg.dataM.instr.ctl.csrwrite;
    assign csr.wa = wreg.dataM.instr.csr_addr;
    assign csr.wd = wreg.dataM.csr;

endmodule




`endif