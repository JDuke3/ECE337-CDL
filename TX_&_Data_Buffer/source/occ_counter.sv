`timescale 1ns / 10ps

module occ_counter (
    input logic clk, n_rst, flush, clear, wenable, renable,
    output logic [6:0] buffer_occupancy
);

logic [6:0] next_buffer_occupancy;

always_ff @(posedge clk, negedge n_rst) begin
    if(n_rst == 1'b0) begin
        buffer_occupancy <= '0;
    end
    else begin
        buffer_occupancy <= next_buffer_occupancy;
    end
end

always_comb begin
    if(flush | clear) begin
        next_buffer_occupancy = '0;
    end
    else if(buffer_occupancy == 7'b1000000) begin
        next_buffer_occupancy = buffer_occupancy;
    end
    else if(wenable & ~renable) begin
        next_buffer_occupancy = buffer_occupancy + 1;
    end
    else if(~wenable & renable) begin
        next_buffer_occupancy = buffer_occupancy - 1;
    end
    else begin
        next_buffer_occupancy = buffer_occupancy;
    end
end

endmodule

