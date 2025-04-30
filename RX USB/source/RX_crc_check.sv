`timescale 1ns / 10ps

module RX_crc_check (
    input clk, n_rst,
    input logic EOP,
    input logic [1:0] trans_type,
    input logic [15:0] crc,
    output logic crc_err
);
    logic next_crc_error;

    localparam TOKEN_DUMMY_CRC = 5'b01100;
    localparam DATA_DUMMY_CRC = 16'b1000000000001101;

    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            crc_err <= 1'b0;
        end
        else begin
            crc_err <= next_crc_error;
        end
    end

    always_comb begin
        next_crc_error = 1'b0;
        if(EOP) begin
            case(trans_type)
                2'b01: begin
                    if(crc[15:11] != TOKEN_DUMMY_CRC) begin
                        next_crc_error = 1'b1;
                    end
                end
                2'b10: begin
                    if(crc != DATA_DUMMY_CRC) begin
                        next_crc_error = 1'b1;
                    end
                end
                default: begin
                    next_crc_error = 1'b0;
                end
            endcase
        end
    end


endmodule

