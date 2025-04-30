`timescale 1ns / 10ps

module usb_data_buffer (
    input logic clk, n_rst, clear, flush, store_rx_packet_data, store_tx_data, get_rx_data, get_tx_packet_data,
    input logic [7:0] tx_data, rx_packet_data,
    output logic [6:0] buffer_occupancy,
    output logic [7:0] rx_data, tx_packet_data
);

logic wenable, renable;
logic [5:0] waddr, raddr;
logic [7:0] wdata, rdata;
logic [7:0] register [0:63];
logic [7:0] next_register [0:63];

waddr_counter WADDR (.clk(clk), .n_rst(n_rst), .flush(flush), .clear(clear), .wenable(wenable), .buffer_occupancy(buffer_occupancy), .waddr(waddr));
raddr_counter RADDR (.clk(clk), .n_rst(n_rst), .flush(flush), .clear(clear), .renable(renable), .waddr(waddr), .raddr(raddr));
occ_counter BUFF_OCC (.clk(clk), .n_rst(n_rst), .flush(flush), .clear(clear), .wenable(wenable), .renable(renable), .buffer_occupancy(buffer_occupancy));

// Register Latch //
always_ff @(posedge clk, negedge n_rst) begin
    if(n_rst == 1'b0) begin
        register <= {default:0};
    end
    else begin
        register <= next_register;
    end
end


// Write Logic //
always_comb begin
    if(store_rx_packet_data) begin
        wenable = 1'b1;
        wdata = rx_packet_data;
    end
    else if(store_tx_data) begin
        wenable = 1'b1;
        wdata = tx_data;
    end
    else begin
        wenable = 1'b0;
        wdata = '0;
    end
end


// Read Logic //
always_comb begin
    if(get_rx_data) begin
        rx_data = rdata;
    end
    else begin
        rx_data = '0;
    end

    if(get_tx_packet_data) begin
        tx_packet_data = rdata;
    end
    else begin
        tx_packet_data = '0;
    end


    if(get_rx_data | get_tx_packet_data) begin
        renable = 1'b1;
    end
    else begin
        renable = 1'b0;
    end
end


// Next Register Logic //
always_comb begin
    next_register = register;
    if(wenable) begin
        next_register [waddr] = wdata;
    end
end


// Rdata Logic //
always_comb begin
    rdata = register[raddr];
end

endmodule

