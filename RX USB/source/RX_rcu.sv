`timescale 1ns / 10ps

module RX_rcu (
    input clk, n_rst,
    input logic shift_strobe,
    input logic edge_flag,
    input logic Pid_err, EOP, byte_done,
    input logic crc_err,
    input logic [1:0] trans_type, crc_bit_value,
    input [15:0] parallel_out,
    output logic Pid_en,
    output logic Flush, Store_RX_Packet_Data, RX_Error, RX_Data_ready, RX_Transfer_Active
);
    typedef enum logic [3:0] {  
        IDLE, CHECK_SYNC, ENABLE_PID, CHECK_PID, ENABLE_PACK, STORE_PACK, WAIT, EOP1, EOP2, ERROR1, ERROR2, OUTPUT
    } state_type;
    state_type state, next_state;

    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state;
        case(state)
            IDLE: begin
                if(edge_flag) begin
                    next_state = CHECK_SYNC;
                end
            end
            CHECK_SYNC: begin
                if(parallel_out[15:8] == 8'b00000001 && shift_strobe) begin
                    next_state = ENABLE_PID;
                end
                else if(EOP) begin
                    next_state = ERROR1;
                end
            end
            ENABLE_PID: begin
                Pid_en = 1;
                if(byte_done && parallel_out[15:8] != 8'b00000001) begin
                    next_state = CHECK_PID;
                end
                else if(EOP && shift_strobe) begin
                    next_state = ERROR1;
                end
            end
            CHECK_PID: begin
                Pid_en = 1;
                if(!Pid_err && trans_type) begin
                    next_state = WAIT;
                end
                else if(EOP && shift_strobe) begin
                    next_state = ERROR1;
                end
            end
            WAIT: begin
                if(byte_done) begin
                    next_state = ENABLE_PACK;
                end
            end
            ENABLE_PACK: begin
                Pid_en = 0;
                if(shift_strobe && !Pid_err) begin
                    next_state = STORE_PACK;
                end
                else if(EOP && shift_strobe) begin
                    next_state = ERROR1;
                end
            end
            STORE_PACK: begin
                if(EOP && byte_done) begin
                    next_state = EOP1;
                end
                else if(!EOP && byte_done) begin
                    next_state = ENABLE_PACK;
                end
            end
            EOP1: begin
                if(shift_strobe) begin
                    next_state = EOP2;
                end
            end
            EOP2: begin
                if(shift_strobe) begin
                    next_state = OUTPUT;
                end
            end
            OUTPUT: begin
                if(crc_err) begin
                    next_state = ERROR1;
                end
                else begin
                    next_state = IDLE;
                end
            end
            ERROR1: begin
                if(shift_strobe) begin
                    next_state = ERROR2;
                end
            end
            ERROR2: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always_comb begin
        case(state)
            IDLE: begin
                Flush = 1'b0;
                RX_Transfer_Active = 1'b0;
                RX_Error = 1'b0;
                RX_Data_ready = 1'b0;
                Store_RX_Packet_Data = 1'b0;
            end
            CHECK_SYNC: begin
                Flush = 1'b1;
                RX_Transfer_Active = 1'b1;
                RX_Error = 1'b0;
                RX_Data_ready = 1'b0;
                Store_RX_Packet_Data = 1'b0;
            end
            ERROR1: begin
                Flush = 1'b1;
                RX_Transfer_Active = 1'b0;
                RX_Error = 1'b1;
                RX_Data_ready = 1'b0;
                Store_RX_Packet_Data = 1'b0;
            end
            ERROR2: begin
                Flush = 1'b1;
                RX_Transfer_Active = 1'b0;
                RX_Error = 1'b1;
                RX_Data_ready = 1'b0;
                Store_RX_Packet_Data = 1'b0;
            end
            STORE_PACK: begin
                Flush = 1'b0;
                RX_Transfer_Active = 1'b1;
                RX_Error = 1'b0;
                RX_Data_ready = 1'b0;
                Store_RX_Packet_Data = 1'b1;
            end
            OUTPUT: begin
                Flush = 1'b0;
                RX_Transfer_Active = 1'b1;
                RX_Error = 1'b0;
                RX_Data_ready = 1'b1;
                Store_RX_Packet_Data = 1'b0;
            end
            default: begin
                Flush = 1'b0;
                RX_Transfer_Active = 1'b1;
                RX_Error = 1'b0;
                RX_Data_ready = 1'b0;
                Store_RX_Packet_Data = 1'b0;
            end
        endcase
    end

endmodule
