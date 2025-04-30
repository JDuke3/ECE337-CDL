`timescale 1ns / 10ps

module waddr_counter (
    input logic clk, n_rst, flush, clear, wenable,
    input logic [6:0] buffer_occupancy,
    output logic [5:0] waddr
);

logic [5:0] next_waddr;

always_ff @(posedge clk, negedge n_rst) begin
    if(n_rst == 1'b0) begin
        waddr <= '0;
    end
    else begin
        waddr <= next_waddr;
    end
end

always_comb begin
    if(flush | clear) begin
        next_waddr = '0;
    end
    else if(waddr == 6'b111111) begin
        next_waddr = '0;
    end
    else if(wenable & (buffer_occupancy != 7'b1000000)) begin
        next_waddr = waddr + 1;
    end
    else begin
        next_waddr = waddr;
    end
end

endmodule

