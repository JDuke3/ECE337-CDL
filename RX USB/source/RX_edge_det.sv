`timescale 1ns / 10ps

module RX_edge_det (
    input clk, n_rst,
    input logic DP_sync,
    output logic edge_flag
);
    logic ff1, ff2;
    logic next_edge_flag;

    always_ff @(posedge clk, negedge n_rst ) begin
        if(1'b0 == n_rst) begin
            ff1 <= 1'b1;
            ff2 <= 1'b1;
            edge_flag <= 1'b0;
        end
        else begin
            ff1 <= DP_sync;
            ff2 <= ff1;
            edge_flag <= next_edge_flag;
        end
    end

    always_comb begin
        next_edge_flag = (ff1 & ~ff2);
    end


endmodule