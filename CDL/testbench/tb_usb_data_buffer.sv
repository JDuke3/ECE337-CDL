`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_usb_data_buffer ();

    localparam CLK_PERIOD = 10ns;

    //initial begin
        //$dumpfile("waveform.vcd");
        //$dumpvars;
    //end

    logic clk, n_rst, clear, flush, store_rx_packet_data, store_tx_data, get_rx_data, get_tx_packet_data;
    logic [7:0] tx_data, rx_packet_data;
    logic [6:0] buffer_occupancy;
    logic [7:0] rx_data, tx_packet_data;

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

    usb_data_buffer DUT (.clk(clk), .n_rst(n_rst), .flush(flush), .store_rx_packet_data(store_rx_packet_data),
        .store_tx_data(store_tx_data), .get_rx_data(get_rx_data),
        .get_tx_packet_data(get_tx_packet_data), .tx_data(tx_data), .rx_packet_data(rx_packet_data),
        .buffer_occupancy(buffer_occupancy), .rx_data(rx_data), .tx_packet_data(tx_packet_data));

    initial begin
        n_rst = 1;
        clear = 0;
        flush = 0;
        store_rx_packet_data = 0;
        store_tx_data = 0;
        get_rx_data = 0;
        get_tx_packet_data = 0;
        tx_data = '0;
        rx_packet_data = '0;

        reset_dut;


        // STORE FROM RX
        @(negedge clk);
        rx_packet_data = 8'hFF;
        store_rx_packet_data = 1;
        @(negedge clk);
        rx_packet_data = 8'hDD;
        store_rx_packet_data = 1;
        @(negedge clk)
        @(negedge clk)
        @(negedge clk)
        rx_packet_data = 8'hCC;
        store_rx_packet_data = 1;
        @(negedge clk)
        store_rx_packet_data = 0;
        @(negedge clk)
        @(negedge clk)

        get_rx_data = 1;
        @(negedge clk)
        @(negedge clk)
        @(negedge clk)

        $finish;
    end
endmodule

/* verilator coverage_on */

