`timescale 1ns / 10ps

module RX_timer (
    input clk, n_rst, 
    input logic clear, count_enable,
    input logic [4:0] rollover_val,
    output logic rollover_flag, 
    output logic [4:0] count_out
);
    logic [4:0] temp_count;
    logic rollover_8_1, rollover_9, rollover_8_2;

    RX_flex_counter #(5) tim1 (
        .clk(clk), .n_rst(n_rst), .clear(clear), 
        .count_enable(count_enable), .rollover_val(rollover_val), 
        .count_out(temp_count), .rollover_flag()
    );

    RX_flex_counter #(4) tim2 (
        .clk(clk), .n_rst(n_rst), .clear(clear), 
        .count_enable(count_enable && (temp_count < 5'd8)), .rollover_val(4'd8), 
        .count_out(), .rollover_flag(rollover_8_1)
    );

    RX_flex_counter #(4) tim3 (
        .clk(clk), .n_rst(n_rst), .clear(clear), 
        .count_enable(count_enable && (temp_count >= 5'd8) && (temp_count < 5'd17)), .rollover_val(4'd9), 
        .count_out(), .rollover_flag(rollover_9)
    );

    RX_flex_counter #(4) tim4 (
        .clk(clk), .n_rst(n_rst), .clear(clear), 
        .count_enable(count_enable && (temp_count >= 5'd17)), .rollover_val(4'd8), 
        .count_out(), .rollover_flag(rollover_8_2)
    );
    assign count_out = temp_count;
    assign rollover_flag = rollover_8_1 | rollover_9 | rollover_8_2;

endmodule