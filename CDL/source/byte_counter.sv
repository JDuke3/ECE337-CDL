`timescale 1ns / 10ps

module byte_counter (
    input logic clk, n_rst, start,
    output logic rollover_flag
);

logic [3:0] count, next_count;

// Counter Latch //
always_ff @(posedge clk, negedge n_rst) begin
    if(n_rst == 1'b0) begin
        count <= 4'b0;
    end
    else begin
        count <= next_count;
    end
end

// Next Count Logic //
always_comb begin
    if((count == 3'b0) & start) begin
        next_count = count + 1;
    end
    else if((count == 3'b111) | (count == 3'b0)) begin // rv = 7
        next_count = 3'b0;
    end
    else begin
        next_count = count + 1;
    end
end

// Output Logic //
always_comb begin
    if(count == 3'b111) begin
        rollover_flag = 1'b1;
    end
    else begin
        rollover_flag = 1'b0;
    end
end

endmodule

