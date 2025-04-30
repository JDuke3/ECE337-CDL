`timescale 1ns / 10ps

module RX_flex_counter #(
    parameter SIZE = 4
) (
    input logic clk,
    input logic n_rst,
    input logic clear,
    input logic count_enable,
    input logic [SIZE-1:0] rollover_val,
    output logic [SIZE-1:0] count_out,
    output logic rollover_flag
);
    logic [SIZE-1:0] next_count_out;
    logic next_rollover_flag;

    always_comb begin
        next_count_out = count_out;
        if(clear) begin
            next_count_out = 0;
        end
        else if(count_enable) begin
                next_count_out = count_out + 1;
                if(count_out >= rollover_val) begin
                    next_count_out = 1;
                end
        end
    end
    always_comb begin
        if(next_count_out == rollover_val)
            next_rollover_flag = 1;
        else
            next_rollover_flag = 0;
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            count_out <= 0;
            rollover_flag <= 0;
        end
        else begin
            count_out <= next_count_out;
            rollover_flag <= next_rollover_flag;
        end
    end

endmodule