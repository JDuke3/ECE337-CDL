`timescale 1ns / 10ps

module RX_Pid_Byte #(
    // parameters
) (
    input clk, n_rst,
    input logic [7:0] Pid_data,
    input logic Pid_en,
    output logic [3:0] RX_Packet,
    output logic Pid_err,
    output logic [1:0] trans_type
);
    logic [3:0] next_RX_Packet;
    localparam OUT = 4'b0001;
    localparam IN = 4'b1001;
    localparam DATA0 = 4'b1100;
    localparam DATA1 = 4'b1101;
    localparam ACK = 4'b0100;

    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            RX_Packet <= 0;
        end
        else begin
            RX_Packet <= next_RX_Packet;
        end
    end

    always_comb begin
        next_RX_Packet = RX_Packet;
        Pid_err = 0;
        trans_type = 0;
        if(Pid_en) begin
            case(Pid_data)
                8'b11100001: begin
                    next_RX_Packet = OUT;
                    trans_type = 2'b01;
                end
                8'b01101001: begin
                    next_RX_Packet = IN;
                    trans_type = 2'b01;
                end
                8'b11000011: begin
                    next_RX_Packet = DATA0;
                    trans_type = 2'b10;
                end
                8'b01001011: begin
                    next_RX_Packet = DATA1;
                    trans_type = 2'b10;
                end
                8'b11010010: begin
                    next_RX_Packet = ACK;
                    trans_type = 2'b11;
                end
                default: begin
                    next_RX_Packet = 0;
                    trans_type = 0;
                    Pid_err = 1;
                end
            endcase
        end
    end


endmodule

