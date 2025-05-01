`timescale 1ns / 10ps

module RX_edge_det (
    input clk, n_rst,
    input logic DP_IN,
    output logic edge_flag
);
    logic ff1, ff2;

    always_ff @(posedge clk, negedge n_rst ) begin
        if(1'b0 == n_rst) begin
            ff1 <= 1'b1;
            ff2 <= 1'b1;
        end
        else begin
            ff1 <= DP_IN;
            ff2 <= ff1;
        end
    end

    always_comb begin
        edge_flag = (ff1 ^ ff2);
    end


endmodule
