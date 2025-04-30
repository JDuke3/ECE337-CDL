`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_usb_tx ();

    localparam CLK_PERIOD = 10ns;

    //initial begin
        //$dumpfile("waveform.vcd");
        //$dumpvars;
    //end

    logic clk, n_rst;
    logic [7:0] tx_packet_data;
    logic [3:0] tx_packet;
    logic [6:0] buffer_occupancy;
    logic get_tx_packet_data, tx_transfer_active, tx_error, dp_out, dm_out;


    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    task reset_dut;
    begin
        n_rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    task send_byte;
    begin
        @(negedge clk);
        tx_packet = 4'b0;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(posedge clk);
    end
    endtask

    usb_tx DUT (.clk(clk), .n_rst(n_rst), .tx_packet_data(tx_packet_data), .tx_packet(tx_packet),
    .buffer_occupancy(buffer_occupancy), .get_tx_packet_data(get_tx_packet_data), .tx_transfer_active(tx_transfer_active),
    .tx_error(tx_error), .dp_out(dp_out), .dm_out(dm_out));

    initial begin
        n_rst = 1;
        tx_packet = 4'b0;
        tx_packet_data = 8'b0;
        buffer_occupancy = 7'b0;

        reset_dut;
        @(negedge clk);

        tx_packet = 4'b0010;
        
        send_byte;
        send_byte;
        send_byte;
        send_byte;

        buffer_occupancy = 7'b11;
        tx_packet_data = 8'hDD;
        tx_packet = 4'b0;

        $finish;
    end
endmodule

/* verilator coverage_on */

