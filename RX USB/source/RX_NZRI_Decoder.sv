`timescale 1ns / 10ps

module RX_NRZI_Decoder (
    input clk, n_rst, 
    input logic DP_sync, DM_sync,
    input logic shift_strobe,
    output logic EOP,
    output logic d_orig, d_enable
);
    logic DP_prev, DM_prev;

    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            DP_prev <= 1'b1;
            DM_prev <= 1'b0;
        end
        else if(shift_strobe) begin
            DP_prev <= DP_sync;
            DM_prev <= DP_sync;
        end
        else begin
            DP_prev <= DP_prev;
            DM_prev <= DM_prev;
        end
    end

    always_comb begin
        if(!DP_sync && !DM_sync) begin
            EOP = 1;
            d_orig = 1'b0;
            d_enable = 1'b0;
        end
        else if(((DP_sync && !DM_sync) || (DP_sync && DM_sync)) && ((DP_prev && !DM_prev) || (!DP_prev && DM_prev))) begin
            EOP = 1;
            if(DP_sync == DP_prev) begin
                d_orig=1;
            end
            else begin
                d_orig = 0;
            end
            d_enable = 1'b1;
        end
        else begin
            EOP = 0;
            d_orig = 1'b0;
            d_enable = 1'b0;
        end
    end

endmodule

