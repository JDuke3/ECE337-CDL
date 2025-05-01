`timescale 1ns / 10ps

module usb_receiver #(
    // parameters
) (
    input clk, n_rst,
    input logic DP_IN, DM_IN,
    output logic RX_Data_ready, RX_Transfer_Active, RX_Error, Flush,
    output logic [3:0] RX_Packet,
    output logic Store_RX_Packet_Data,
    output logic [7:0] RX_Packet_Data
);
logic DM_sync, DP_sync;
logic EOP, shift_strobe;
logic byte_done, packet_done;
logic d_orig, d_enable;
logic [15:0] parallel_out;
logic [1:0] trans_type;
logic Pid_en, Pid_err, crc_err;
logic [15:0] crc;
logic [7:0] Pid_data;
logic [4:0] count_out;
logic [1:0] crc_bit_value;

RX_sync #(0) low (.clk(clk), .n_rst(n_rst), .async_in(DM_IN), .sync_out(DM_sync));
RX_sync #(1) high (.clk(clk), .n_rst(n_rst), .async_in(DP_IN), .sync_out(DP_sync));
RX_edge_det edg (.clk(clk), .n_rst(n_rst), .DP_IN(DP_IN), .edge_flag(edge_flag));
RX_NRZI_Decoder mod3(.clk(clk), .n_rst(n_rst), .DP_sync(DP_sync), .DM_sync(DM_sync), 
.shift_strobe(shift_strobe), .EOP(EOP), .d_orig(d_orig));
// RX_timer tim (.clk(clk), .n_rst(n_rst), .clear(RX_Data_ready), .count_enable(RX_Transfer_Active), 
// .rollover_val(5'd25), .rollover_flag(shift_strobe), .count_out(count_out));
RX_flex_counter cn (.clk(clk), .n_rst(n_rst), .clear(RX_Data_ready), .count_enable(RX_Transfer_Active), 
.rollover_val(4'd8), .count_out(), .rollover_flag(shift_strobe));
RX_flex_counter cnt (.clk(clk), .n_rst(n_rst), .clear(RX_Data_ready), .count_enable(shift_strobe), 
.rollover_val(4'd8), .count_out(), .rollover_flag(byte_done));
RX_flex_sr #(16, 0) shift_left (.clk(clk), .n_rst(n_rst), .shift_enable(shift_strobe), 
.load_enable(), .serial_in(d_orig), .parallel_in(), .serial_out(), .parallel_out(parallel_out));
RX_rcu rxrcu (.clk(clk), .n_rst(n_rst), .shift_strobe(shift_strobe), .edge_flag(edge_flag), .Pid_en(Pid_en),
.Pid_err(Pid_err), .EOP(EOP), .byte_done(byte_done), .crc_err(crc_err), .trans_type(trans_type), 
.parallel_out(parallel_out), .crc_bit_value(crc_bit_value), .Flush(Flush), .Store_RX_Packet_Data(Store_RX_Packet_Data), .RX_Error(RX_Error), .RX_Data_ready(RX_Data_ready), .RX_Transfer_Active(RX_Transfer_Active));
RX_crc_check crc_byte (.clk(clk), .n_rst(n_rst), .EOP(EOP), .trans_type(trans_type), .crc_err(crc_err), .crc(crc));
RX_Pid_Byte pid (.clk(clk), .n_rst(n_rst), .Pid_data(Pid_data), .Pid_en(Pid_en), .RX_Packet(RX_Packet), .Pid_err(Pid_err), .trans_type(trans_type));

always_comb begin
    RX_Packet_Data = parallel_out[7:0];
    Pid_data = parallel_out[15:8];
    crc = 16'b0;
    if(EOP) begin
        case(trans_type)
            2'b01: begin
                crc = {11'b0, parallel_out[15:11]};
            end
            2'b10: begin
                crc = parallel_out;
            end
            default: begin
                crc = 16'b0;
            end
        endcase
    end
end


endmodule
