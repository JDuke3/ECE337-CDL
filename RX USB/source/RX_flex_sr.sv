`timescale 1ns / 10ps

module RX_flex_sr #(
    parameter SIZE = 8,
    parameter MSB_FIRST = 0
) (
    input logic clk,
    input logic n_rst,
    input logic shift_enable,
    input logic load_enable,
    input logic serial_in,
    input logic [SIZE-1:0] parallel_in,
    output logic serial_out,
    output logic [SIZE-1:0] parallel_out
);
    logic [SIZE-1:0] next_parallel_out;

    if(MSB_FIRST)
        assign serial_out = parallel_out[SIZE-1];
    else
        assign serial_out = parallel_out[0];

    always_comb begin
        if(load_enable)
            next_parallel_out = parallel_in;
        else begin
            if(shift_enable) begin
                if(MSB_FIRST) begin
                    next_parallel_out = {parallel_out[SIZE-2:0], serial_in};
                end
                else begin
                    next_parallel_out = {serial_in, parallel_out[SIZE-1:1]};
                end
            end
            else
                next_parallel_out = parallel_out;
        end
    end
    
    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            parallel_out <= 4'b1111;
        end
        else begin
            parallel_out <= next_parallel_out;
        end
    end

endmodule