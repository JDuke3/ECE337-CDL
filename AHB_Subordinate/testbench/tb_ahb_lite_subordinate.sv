`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_ahb_lite_subordinate ();

    localparam CLK_PERIOD = 10ns;
    localparam TIMEOUT = 1000;

    localparam BURST_SINGLE = 3'd0;
    localparam BURST_INCR   = 3'd1;
    localparam BURST_WRAP4  = 3'd2;
    localparam BURST_INCR4  = 3'd3;
    localparam BURST_WRAP8  = 3'd4;
    localparam BURST_INCR8  = 3'd5;
    localparam BURST_WRAP16 = 3'd6;
    localparam BURST_INCR16 = 3'd7;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;

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

    // bus model signals
    logic enqueue_transaction_en;
    logic transaction_write;
    logic transaction_fake;
    logic [3:0] transaction_addr;
    logic [31:0] transaction_data;
    logic transaction_error;
    logic [2:0] transaction_size;
    logic [2:0] transaction_burst;

    logic model_reset;
    logic enable_transactions;
    integer current_addr_transaction_num;
    integer current_addr_beat_num;
    logic current_addr_transaction_error;
    integer current_data_transaction_num;
    integer current_data_beat_num;
    logic current_data_transaction_error;
    //

    //AHB Signals
    logic hsel;
    logic [1:0] htrans;
    logic [2:0] hburst;
    logic [3:0] haddr;
    logic [1:0] hsize;
    logic hwrite;
    logic [31:0] hwdata;
    logic [31:0] hrdata;
    logic hresp;
    logic hready;

    //localparams
    localparam DATA_BUFFER_ADDR  = 4'h0; //4-byte
    localparam STATUS_ADDR       = 4'h4; //2-byte
    localparam ERROR_ADDR        = 4'h6; //2-byte
    localparam BUFFER_OCCU_ADDR   = 4'h8; //1-byte
    localparam TX_CTRL_ADDR      = 4'hC; //1-byte
    localparam FLUSH_CTRL_ADDR   = 4'hD; //1-byte

    //Packet Type
    localparam OUT = 4'b0001;
    localparam IN = 4'b1001;
    localparam DATA0 = 4'b0011;
    localparam DATA1 = 4'b1011;
    localparam ACK = 4'b0010;
    localparam NAK = 4'b1010;
    localparam STALL = 4'b1110;

    // DUT signals
    // DUT specific signals
    // Additional signals to mock USB RX/TX behavior
    logic rx_data_ready;
    logic rx_error;
    logic rx_transfer_active;
    logic [7:0] rx_data;
    logic [3:0] rx_packet;
    logic get_rx_data;
    
    logic tx_transfer_active;
    logic tx_error;
    logic [3:0] tx_packet;
    logic [7:0] tx_data;
    logic store_tx_data;

    logic [7:0] buffer_occupancy;
    logic clear;

    logic d_mode;

    ahb_lite_subordinate DUT (
        .clk(clk), 
        .n_rst(n_rst),
        .hsel(hsel),
        .haddr(haddr),
        .htrans(htrans),
        .hsize(hsize),
        .hwrite(hwrite),
        .hwdata(hwdata),
        .hburst(hburst),
        .rx_packet(rx_packet),
        .rx_data_ready(rx_data_ready),
        .rx_transfer_active(rx_transfer_active),
        .rx_error(rx_error),
        .tx_transfer_active(tx_transfer_active),
        .tx_error(tx_error),
        .rx_data(rx_data),
        .buffer_occupancy(buffer_occupancy),
        .hrdata(hrdata),
        .hready(hready),
        .hresp(hresp),
        .tx_data(tx_data),
        .tx_packet(tx_packet),
        .get_rx_data(get_rx_data),
        .store_tx_data(store_tx_data),
        .clear(clear),
        .d_mode(d_mode)
    );

    ahb_model_updated #(
        .ADDR_WIDTH(4),
        .DATA_WIDTH(4)
    ) BFM ( .clk(clk),
        // AHB-Subordinate Side
        .hsel(hsel),
        .haddr(haddr),
        .hsize(hsize),
        .htrans(htrans),
        .hburst(hburst),
        .hwrite(hwrite),
        .hwdata(hwdata),
        .hrdata(hrdata),
        .hresp(hresp),
        .hready(hready)
    );


    // bus model tasks
    task reset_model;
    begin
        model_reset = 1'b1;
        #(0.1);
        model_reset = 1'b0;
    end
    endtask

    task enqueue_transaction;
        input logic for_dut;
        input logic read_write;
        input logic [3:0] address;
        input logic [15:0] data;
        input logic expected_error;
        input logic size;
    begin
        // Make sure enqueue flag is low (will need a 0->1 pulse later)
        enqueue_transaction_en = 1'b0;
        #(0.1ns);
    
        // Setup info about transaction
        transaction_fake  = ~for_dut;
        transaction_write = read_write;
        transaction_addr  = address;
        transaction_data  = data;
        transaction_error = expected_error;
        transaction_size  = {2'b00,size};
    
        // Pulse the enqueue flag
        enqueue_transaction_en = 1'b1;
        #(0.1ns);
        enqueue_transaction_en = 1'b0;
    end
    endtask


     // Read from a register without checking the value
    task enqueue_poll ( input logic [3:0] addr, input logic [1:0] size );
    logic [31:0] data [];
        begin
            data = new [1];
            data[0] = {32'hXXXX};
            //              Fields: hsel,  R/W, addr, data, exp err,         size, burst, chk prdata or not
            BFM.enqueue_transaction(1'b1, 1'b0, addr, data,    1'b0, {1'b0, size},  3'b0,            1'b0);
        end
    endtask


    // Read from a register until a requested value is observed
    task poll_until ( input logic [3:0] addr, input logic [1:0] size, input logic [31:0] data);
        int iters;
        begin
            for (iters = 0; iters < TIMEOUT; iters++) begin
                enqueue_poll(addr, size);
                execute_transactions(1);
                if(BFM.get_last_read() == data) break;
            end
            if(iters >= TIMEOUT) begin
                $error("Bus polling timeout hit.");
            end
        end
    endtask


    // Read Transaction, verifying a specific value is read
    task enqueue_read ( input logic [3:0] addr, input logic [1:0] size, input logic [31:0] exp_read );
        logic [31:0] data [];
        begin
            data = new [1];
            data[0] = exp_read;
            BFM.enqueue_transaction(1'b1, 1'b0, addr, data, 1'b0, {1'b0, size}, 3'b0, 1'b1);
        end
    endtask


    // Write Transaction
    task enqueue_write ( input logic [3:0] addr, input logic [1:0] size, input logic [31:0] wdata );
        logic [31:0] data [];
        begin
            data = new [1];
            data[0] = wdata;
            BFM.enqueue_transaction(1'b1, 1'b1, addr, data, 1'b0, {2'b0, size}, 3'b0, 1'b0);
        end
    endtask


    // Write Transaction Intended for a different subordinate from yours
    task enqueue_fakewrite ( input logic [3:0] addr, input logic [1:0] size, input logic [31:0] wdata );
        logic [31:0] data [];
        begin
            data = new [1];
            data[0] = wdata;
            BFM.enqueue_transaction(1'b0, 1'b1, addr, data, 1'b0, {1'b0, size}, 3'b0, 1'b0);
        end
    endtask


    // Create a burst read of size based on the burst type.
    // If INCR, burst size dependent on dynamic array size
    task enqueue_burst_read ( input logic [3:0] base_addr, input logic [1:0] size, input logic [2:0] burst, input logic [31:0] data [] );
        BFM.enqueue_transaction(1'b1, 1'b0, base_addr, data, 1'b0, {1'b0, size}, burst, 1'b1);
    endtask


    // Create a burst write of size based on the burst type.
    task enqueue_burst_write ( input logic [3:0] base_addr, input logic [1:0] size, input logic [2:0] burst, input logic [31:0] data [] );
        BFM.enqueue_transaction(1'b1, 1'b1, base_addr, data, 1'b0, {1'b0, size}, burst, 1'b1);
    endtask


    // Run n transactions, where a k-beat burst counts as k transactions.
    task execute_transactions (input int num_transactions);
        BFM.run_transactions(num_transactions);
    endtask


    task simulate_usb_packet;
        input logic [3:0] packet_type;
        input logic [7:0] data;
    begin
        // Start packet reception
        rx_transfer_active = 1'b1;
        @(posedge clk);
        @(posedge clk);
        
        // Signal packet completion and data
        rx_data_ready = 1'b1;
        rx_packet = packet_type;
        rx_data = data;
        @(posedge clk);
        
        // End packet reception
        rx_transfer_active = 1'b0;
        @(posedge clk);
        rx_data_ready = 1'b0;
    end
    endtask


    logic [31:0] data [];

    initial begin
         n_rst = 1;
        reset_model();
        reset_dut();

        /****** EXAMPLE CODE ******/

        // Always put data LSB-aligned. The model will automagically move bytes to their proper position.
            /*
            enqueue_read(3'h1, 1'b0, 31'h00BB);
            enqueue_write(3'h2, 1'b1, 31'h00BB);
            
            // Example Burst Setup - Dynamic Array Required
            data = new [8];
            data = {32'h8888_8888, 32'h7777_7777,32'h6666_6666,32'h5555_5555,32'h4444_4444,32'h3333_3333,32'h2222_2222,32'h1111_1111};
            enqueue_burst_read(4'hC, 1'b1, BURST_WRAP8, data);
            execute_transactions(10); // Burst counts as 8 transactions for 8 beats
            */
        /****** EXAMPLE CODE ******/
        // Initialization
        rx_transfer_active = 1;
        rx_error = 0;
        rx_data_ready = 0;
        rx_packet = 0;
        tx_transfer_active = 0;
        tx_error = 1;
        buffer_occupancy = 2;


        #(5*CLK_PERIOD);
        // TEST 1: SINGLE BYTE READ/WRITE
        enqueue_write(TX_CTRL_ADDR, 2'b00, 32'h00AA);
        execute_transactions(1);
        enqueue_read(TX_CTRL_ADDR, 2'b00, 32'h0000);
        execute_transactions(1);
        #(2*CLK_PERIOD);

        // TEST 2: Overlapping SINGLE BYTE
        enqueue_write(TX_CTRL_ADDR, 2'b00, 32'h00AA);
        enqueue_read(TX_CTRL_ADDR, 2'b00, 32'h00AA);
        execute_transactions(2);
        #(2*CLK_PERIOD);

        // TEST 3: HALF WORD READ
        enqueue_read(STATUS_ADDR, 2'b01, 32'h0100);
        execute_transactions(1);
        #(2*CLK_PERIOD);

        // TEST 3: HALF WORD READ
        enqueue_read(ERROR_ADDR, 2'b01, 32'h0100);
        execute_transactions(1);
        #(2*CLK_PERIOD);

        // TEST 4: WRITE FULL WORD TO DATA BUFFER
        enqueue_write(DATA_BUFFER_ADDR, 2'b10, 32'hAABBCCDD);
        execute_transactions(1);
        #(5*CLK_PERIOD);
        rx_data = 8'hAA;
        enqueue_read(DATA_BUFFER_ADDR, 2'b10, 32'hAAAAAAAA);
        execute_transactions(1);
        #(5*CLK_PERIOD);

        // TEST 5: WRITE TO FLUSH
        enqueue_write(FLUSH_CTRL_ADDR, 2'b00, 32'h0001);
        execute_transactions(1);
        #(2*CLK_PERIOD);

        // TEST 6: WRITE TO READ-ONLY
        enqueue_write(STATUS_ADDR, 2'b01, 32'hAABB);
        execute_transactions(1);
        #(2*CLK_PERIOD);

        // TEST 7: READ/WRITE TO INVALID ADDR
        enqueue_write(4'hF, 2'b01, 32'hAABB);
        execute_transactions(1);
        enqueue_read(4'hF, 2'b01, 32'h0000);
        execute_transactions(1);
        #(2*CLK_PERIOD);

        // TEST 8: SIZE OVERFLOW
        enqueue_write(FLUSH_CTRL_ADDR, 2'b01, 32'h0001);
        execute_transactions(1);
        #(2*CLK_PERIOD);

        #(5*CLK_PERIOD);

        $finish;

    end
endmodule

/* verilator coverage_on */

