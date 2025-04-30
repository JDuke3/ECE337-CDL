`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_usb_receiver ();

    localparam CLK_PERIOD = 10ns;
    localparam DATA_PERIOD = 8 * CLK_PERIOD;

    localparam PID_IN = 8'b01101001;
    localparam PID_OUT = 8'b11100001;
    localparam DATA0 = 8'b11000011;
    localparam DATA1 = 8'b01001011;
    localparam ACK = 8'b11010010;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic DP_IN, DM_IN;
    logic RX_Data_ready, RX_Transfer_Active, RX_Error, Flush;
    logic [3:0] RX_Packet;
    logic Store_RX_Packet_Data;
    logic [7:0] RX_Packet_Data;
    int test_num;

    logic expected_RX_Data_ready, expected_RX_Transfer_Active, expected_RX_Error, expected_Flush;
    logic [3:0] expected_RX_Packet;
    logic expected_Store_RX_Packet_Data;
    logic [7:0] expected_RX_Packet_Data;
    logic nzri_level;

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

    task send_packet;
        input logic [7:0] data;
        int i;
        begin
            for(i = 0; i < 4'd8; i = i+1) begin
                send_usb_bit(data[i]);
                #(DATA_PERIOD);
            end
        end
    endtask

    task send_EOP;
        int i;
        begin
            @(negedge clk);
            DP_IN = 1'b0;
            DM_IN = 1'b0;
            #(DATA_PERIOD);

            DP_IN = 1'b0;
            DM_IN = 1'b0;
            #(DATA_PERIOD);

            DP_IN = 1'b1;
            DM_IN = 1'b0;
            #(DATA_PERIOD);

        end
    endtask

    task send_usb_bit;
        input logic b;
        int i;
        begin
            if(!b) begin
                nzri_level = !nzri_level;
                for(i=0;i<8;i++) begin
                    DP_IN = nzri_level;
                    DM_IN = !nzri_level;
                    #(DATA_PERIOD);
                end
            end
        end
    endtask


    task check_output;
        logic expected_RX_Data_ready, expected_RX_Transfer_Active, expected_RX_Error, expected_Flush;
        logic [3:0] expected_RX_Packet;
        logic expected_Store_RX_Packet_Data;
        logic [7:0] expected_RX_Packet_Data;
        begin
            if(expected_RX_Data_ready == RX_Data_ready) begin
                $display("RX_Data_ready Test %d Passed", test_num);
            end
            else begin
                $display("RX_Data_ready Test %d Failed", test_num);
            end
            if(expected_RX_Transfer_Active == RX_Transfer_Active) begin
                $display("RX_Transfer_Active Test %d Passed", test_num);
            end
            else begin
                $display("RX_Transfer_Active Test %d Failed", test_num);
            end
            if(expected_RX_Error == RX_Error) begin
                $display("RX_Error Test %d Passed", test_num);
            end
            else begin
                $display("RX_Error Test %d Failed", test_num);
            end
            if(expected_Flush == Flush) begin
                $display("Flush Test %d Passed", test_num);
            end
            else begin
                $display("Flush Test %d Failed", test_num);
            end
            if(expected_RX_Packet == RX_Packet) begin
                $display("RX_Packet Test %d Passed, %b", test_num, RX_Packet);
            end
            else begin
                $display("RX_Packet Test %d Failed", test_num);
            end
            if(expected_Store_RX_Packet_Data == Store_RX_Packet_Data) begin
                $display("Store_RX_Packet_Data Test %d Passed", test_num);
            end
            else begin
                $display("Store_RX_Packet_Data Test %d Failed", test_num);
            end
            if(expected_RX_Packet_Data == RX_Packet_Data) begin
                $display("RX_Packet_Data Test %d Passed", test_num);
            end
            else begin
                $display("RX_Packet_Data Test %d Failed", test_num);
            end
        end
    endtask

    usb_receiver DUT (.clk(clk), .n_rst(n_rst), .DP_IN(DP_IN), .DM_IN(DM_IN), .RX_Data_ready(RX_Data_ready),
    .RX_Transfer_Active(RX_Transfer_Active), .RX_Error(RX_Error), .Flush(Flush),
    .RX_Packet(RX_Packet), .Store_RX_Packet_Data(Store_RX_Packet_Data), .RX_Packet_Data(RX_Packet_Data));

    initial begin
        expected_RX_Data_ready = 1'b0;
        expected_RX_Transfer_Active = 1'b0;
        expected_RX_Error = 1'b0;
        expected_Flush = 1'b0;
        expected_RX_Packet = 4'b0;
        expected_Store_RX_Packet_Data = 1'b0;
        expected_RX_Packet_Data = 8'b11111111;
        
        @(negedge clk)
        test_num = 0;
        n_rst = 1;
        reset_dut;
        #(CLK_PERIOD)

        @(negedge clk)
        test_num = 1;
        DP_IN = 1'b1;
        DM_IN = 1'b0;
        nzri_level = 1'b1;
        reset_dut;
        expected_RX_Packet_Data = 8'b00000001;
        send_packet(8'b00000001);
        check_output;

        @(negedge clk)
        test_num = 2;
        DP_IN = 1'b1;
        DM_IN = 1'b0;
        reset_dut;
        expected_RX_Packet_Data = 8'b00000001;
        send_packet(8'b00000001);

        send_packet(PID_IN);

        send_packet(8'b11000011);

        send_EOP();

        @(negedge clk)
        test_num = 3;
        DP_IN = 1'b1;
        DM_IN = 1'b0;
        reset_dut;
        expected_RX_Packet_Data = 8'b00000001;
        send_packet(8'b00000001);

        send_packet(PID_OUT);

        send_packet(DATA1);

        send_EOP();

        @(negedge clk)
        test_num = 3;
        DP_IN = 1'b1;
        DM_IN = 1'b0;
        reset_dut;
        expected_RX_Packet_Data = 8'b00000001;
        send_packet(8'b10000000);


        send_packet(DATA0);
        send_packet(DATA0);
        send_packet(DATA0);
        send_packet(DATA0);
        send_packet(DATA0);
        send_packet(DATA0);
        send_packet(DATA0);
        send_packet(DATA0);
        send_packet(DATA0);
        send_packet(DATA0);
        send_packet(DATA0);

        send_packet(8'b11010010);

        send_EOP();

        $finish;
    end
endmodule

/* verilator coverage_on */

