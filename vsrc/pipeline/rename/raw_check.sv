`ifndef __RAW_CHECK_SV
`define __RAW_CHECK_SV
`ifdef VERILATOR

`endif

module raw_check 
    import common::*;(
    input creg_addr_t[FETCH_WIDTH-1:0] src1, src2, dst,
    input struct packed {
        logic valid;
        preg_addr_t id;
    }[FETCH_WIDTH-1:0] psrc1_rat, psrc2_rat, pdst_fl,
    output struct packed {
        logic valid;
        preg_addr_t id;
    } [FETCH_WIDTH-1:0] psrc1, psrc2
);
    assign psrc1[0] = psrc1_rat[0];
    assign psrc2[0] = psrc2_rat[0];
	for (genvar i = 1; i < FETCH_WIDTH; i++) begin
		always_comb begin
			psrc1[i] = psrc1_rat[i];
            for (int j = i - 1; j >= 0; j--) begin
                if (src1[i] == dst[j]) begin
                    psrc1[i] = pdst_fl[j];
                    break;
                end
            end
		end
		always_comb begin
			psrc2[i] = psrc2_rat[i];
            for (int k = i - 1; k >= 0; k--) begin
                if (src2[i] == dst[k]) begin
                    psrc2[i] = pdst_fl[k];
                    break;
                end
            end
		end
		
	end
endmodule

`endif