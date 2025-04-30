`timescale 1ns / 10ps

module pts_sr (
    input logic clk, n_rst, start,
    input logic [7:0] data,
    output logic serial_out
);

logic [7:0] sr_data, next_sr_data;

// SR Data Latch //
always_ff @(posedge clk, negedge n_rst) begin
    if(n_rst == 1'b0) begin
        sr_data <= '0;
    end
    else begin
        sr_data <= next_sr_data;
    end
end

// Serial Out Logic //
always_comb begin
    if(start) begin
        next_sr_data = data;
    end
    else begin
        next_sr_data = {sr_data[6:0],1'b0};
    end

    serial_out = sr_data[7];
end


endmodule

