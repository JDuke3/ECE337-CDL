`timescale 1ns / 10ps

module raddr_counter (
    input logic clk, n_rst, flush, clear, renable,
    input logic [5:0] waddr,
    output logic [5:0] raddr
);

logic [5:0] next_raddr;

always_ff @(posedge clk, negedge n_rst) begin
    if(n_rst == 1'b0) begin
        raddr <= '0;
    end
    else begin
        raddr <= next_raddr;
    end
end

always_comb begin
    if(flush | clear) begin
        next_raddr = '0;
    end
    else if(raddr == 6'b111111) begin
        next_raddr = '0;
    end
    else if(renable & (waddr > raddr + 1)) begin
        next_raddr = raddr + 1;
    end
    else begin
        next_raddr = raddr;
    end
end

endmodule

