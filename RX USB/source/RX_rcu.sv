`timescale 1ns / 10ps

module RX_rcu (
    input clk, n_rst,
    input logic shift_strobe,
    input logic edge_flag,
    input logic Pid_en, Pid_err, EOP, byte_done,
    input logic crc_err, d_enable,
    input logic [1:0] trans_type,
    input [15:0] parallel_out,
    output logic Flush, Store_RX_Packet_Data, RX_Error, RX_Data_ready, RX_Transfer_Active
);
    typedef enum logic [3:0] {  
        IDLE, ENABLE_SYNC, CHECK_SYNC, ENABLE_PID, CHECK_PID, ENABLE_PACK, STORE_PACK, WAIT, EOP1, EOP2, ERROR, OUTPUT
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
                    next_state = ENABLE_SYNC;
                end
            end
            ENABLE_SYNC: begin
                if(byte_done) begin
                    next_state = CHECK_SYNC;
                end
            end
            CHECK_SYNC: begin
                if(parallel_out[7:0] == 8'b00000001) begin
                    next_state = ENABLE_PID;
                end
                else begin
                    next_state = ERROR;
                end
            end
            ENABLE_PID: begin
                if(byte_done) begin
                    next_state = CHECK_PID;
                end
                else if(EOP) begin
                    next_state = ERROR;
                end
            end
            CHECK_PID: begin
                if(!Pid_err && trans_type == 2'b01) begin
                    next_state = ENABLE_PACK;
                end
                else if(!Pid_err && trans_type) begin
                    next_state = WAIT;
                end
                else if(Pid_err || EOP) begin
                    next_state = ERROR;
                end
            end
            ENABLE_PACK: begin
                if(byte_done) begin
                    next_state = STORE_PACK;
                end
                else if(EOP && shift_strobe) begin
                    next_state = EOP1;
                end
            end
            STORE_PACK: begin
                if(EOP && shift_strobe) begin
                    next_state = EOP1;
                end
                else if(!EOP &&shift_strobe) begin
                    next_state = ENABLE_PACK;
                end
            end
            WAIT: begin
                if(EOP && shift_strobe) begin
                    next_state = EOP1;
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
                else if(crc_err) begin
                    next_state = ERROR;
                end
            end
            OUTPUT: begin
                next_state = IDLE;
            end
            ERROR: begin
                if(d_enable) begin
                    next_state = IDLE;
                end
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
            ENABLE_SYNC: begin
                Flush = 1'b1;
                RX_Transfer_Active = 1'b1;
                RX_Error = 1'b0;
                RX_Data_ready = 1'b0;
                Store_RX_Packet_Data = 1'b0;
            end
            ERROR: begin
                Flush = 1'b1;
                RX_Transfer_Active = 1'b0;
                RX_Error = 1'b1;
                RX_Data_ready = 1'b0;
                Store_RX_Packet_Data = 1'b0;
            end
            OUTPUT: begin
                Flush = 1'b0;
                RX_Transfer_Active = 1'b1;
                RX_Error = 1'b0;
                RX_Data_ready = 1'b1;
                Store_RX_Packet_Data = 1'b1;
            end
            default: begin
                Flush = 1'b0;
                RX_Transfer_Active = 1'b0;
                RX_Error = 1'b0;
                RX_Data_ready = 1'b0;
                Store_RX_Packet_Data = 1'b0;
            end
        endcase
    end

endmodule

