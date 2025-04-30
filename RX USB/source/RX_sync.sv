`timescale 1ns / 10ps

module RX_sync #(
    parameter RST_VAL = 0
) (
    input logic clk,
    input logic n_rst,
    input logic async_in,
    output logic sync_out
);
    logic ff1_out;

    always_ff @(posedge clk, negedge n_rst ) begin
        if(1'b0 == n_rst)
            ff1_out <= RST_VAL;
        else
            ff1_out <= async_in;
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if(1'b0 == n_rst)
            sync_out <= RST_VAL;
        else
            sync_out <= ff1_out;
    end

endmodule