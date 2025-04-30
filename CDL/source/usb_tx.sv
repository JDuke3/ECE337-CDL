`timescale 1ns / 10ps

module usb_tx (
    input logic clk, n_rst,
    input logic [7:0] tx_packet_data,
    input logic [3:0] tx_packet,
    input logic [6:0] buffer_occupancy,
    output logic get_tx_packet_data, tx_transfer_active, tx_error, dp_out, dm_out
);

// TX controller signals
logic start, serial_out;
logic [7:0] sync, pid, data;

typedef enum logic [3:0] {IDLE,SYNC,SYNC_WAIT,PID,PID_WAIT,DATA,DATA_WAIT,EOF1,EOF2,ERROR} fsm_state;
fsm_state state;
fsm_state next_state;

byte_counter CLKDIV (.clk(clk), .n_rst(n_rst), .start(start), .rollover_flag(rollover_flag));
pts_sr SHIFTREG (.clk(clk), .n_rst(n_rst), .data(data), .start(start), .serial_out(serial_out));
nrzi_enc NRZI (.clk(clk), .n_rst(n_rst), .serial_out(serial_out), .state(state), .dp_out(dp_out), .dm_out(dm_out));


// State Latch //
always_ff @(posedge clk, negedge n_rst) begin
    if(n_rst == 1'b0) begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end


// Nextstate Logic //
always_comb begin
    casez(state)

    IDLE : begin
        if(tx_packet == 4'b0011 | tx_packet == 4'b1011 | tx_packet == 4'b0010 | tx_packet == 4'b1010 | tx_packet == 4'b1110) begin
            next_state = SYNC;
        end
        else if(tx_packet == 4'b0) begin
            next_state = IDLE;
        end
        else begin
            next_state = ERROR;
        end
    end

    SYNC : begin
        next_state = SYNC_WAIT;
    end
    SYNC_WAIT : begin
        if(rollover_flag) begin
            next_state = PID;
        end
        else begin
            next_state = SYNC_WAIT;
        end
    end

    PID : begin
        next_state = PID_WAIT;
    end
    PID_WAIT : begin
        if(rollover_flag & ((tx_packet == 4'b0011) | (tx_packet == 4'b1011))) begin
            next_state = DATA;
        end
        else if(rollover_flag & (tx_packet != 4'b0011) & (tx_packet != 4'b1011)) begin
            next_state = EOF1;
        end
        else begin
            next_state = PID_WAIT;
        end
    end

    DATA : begin
        next_state = DATA_WAIT;
    end
    DATA_WAIT : begin
        if(rollover_flag & (buffer_occupancy != 7'b0)) begin
            next_state = DATA;
        end
        else if(rollover_flag & (buffer_occupancy == 7'b0)) begin
            next_state = EOF1;
        end
        else begin
            next_state = DATA_WAIT;
        end
    end

    EOF1 : begin
        next_state = EOF2;
    end
    EOF2 : begin
        next_state = IDLE;
    end

    ERROR : begin
        if(tx_packet == 4'b0011|4'b1011|4'b0010|4'b1010|4'b1110) begin
            next_state = SYNC;
        end
        else begin
            next_state = ERROR;
        end
    end
    default : begin
        next_state = IDLE;
    end
    endcase
end


// FSM Output Logic //
always_comb begin
    casez(state)

    IDLE : begin
        tx_error = 1'b0;
        tx_transfer_active = 1'b0;
        get_tx_packet_data = 1'b0;
        start = 1'b0;
    end

    SYNC : begin
        tx_error = 1'b0;
        tx_transfer_active = 1'b1;
        get_tx_packet_data = 1'b0;
        start = 1'b1;
    end
    SYNC_WAIT : begin
        tx_error = 1'b0;
        tx_transfer_active = 1'b1;
        get_tx_packet_data = 1'b0;
        start = 1'b0;
    end

    PID : begin
        tx_error = 1'b0;
        tx_transfer_active = 1'b1;
        get_tx_packet_data = 1'b0;
        start = 1'b1;
    end
    PID_WAIT : begin
        tx_error = 1'b0;
        tx_transfer_active = 1'b1;
        get_tx_packet_data = 1'b0;
        start = 1'b0;
    end

    DATA : begin
        tx_error = 1'b0;
        tx_transfer_active = 1'b1;
        get_tx_packet_data = 1'b1;
        start = 1'b1;
    end
    DATA_WAIT : begin
        tx_error = 1'b0;
        tx_transfer_active = 1'b1;
        get_tx_packet_data = 1'b0;
        start = 1'b0;
    end

    EOF1 : begin
        tx_error = 1'b0;
        tx_transfer_active = 1'b1;
        get_tx_packet_data = 1'b0;
        start = 1'b0;
    end
    EOF2 : begin
        tx_error = 1'b0;
        tx_transfer_active = 1'b1;
        get_tx_packet_data = 1'b0;
        start = 1'b0;
    end

    ERROR : begin
        tx_error = 1'b1;
        tx_transfer_active = 1'b0;
        get_tx_packet_data = 1'b0;
        start = 1'b0;
    end

    default : begin
        tx_error = 1'b0;
        tx_transfer_active = 1'b0;
        get_tx_packet_data = 1'b0;
        start = 1'b0;
    end
    endcase
end


// Data MUX //
always_comb begin
    sync = 8'b1;
    pid = {tx_packet,~tx_packet};

    casez(state)
        SYNC : begin
            data = sync;
        end
        SYNC_WAIT : begin
            data = sync;
        end
        PID : begin
            data = pid;
        end
        PID_WAIT : begin
            data = pid;
        end
        DATA : begin
            data = tx_packet_data;
        end
        DATA_WAIT : begin
            data = tx_packet_data;
        end
        default : begin
            data = 8'b0;
        end
    endcase
end


endmodule



