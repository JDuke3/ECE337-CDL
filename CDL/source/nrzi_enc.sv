`timescale 1ns / 10ps

module nrzi_enc (
    input logic clk, n_rst, serial_out,
    input logic [3:0] state,
    output logic dp_out, dm_out
);

logic next_dp_out, next_dm_out;

always_ff @(posedge clk, negedge n_rst) begin
    if(n_rst == 1'b0) begin
        dp_out <= 1'b1;
        dm_out <= 1'b0;
    end
    else begin
        dp_out <= next_dp_out;
        dm_out <= next_dm_out;
    end
end

always_comb begin
    casez(state)

    4'b0000 : begin
        next_dp_out = 1'b1;
        next_dm_out = 1'b0;
    end

    4'b0111 : begin
        next_dp_out = 1'b0;
        next_dm_out = 1'b0;
    end
    4'b1000 : begin
        next_dp_out = 1'b0;
        next_dm_out = 1'b0;
    end

    default : begin
        if(serial_out) begin
            next_dp_out = dp_out;
            next_dm_out = dm_out;
        end
        else begin
            next_dp_out = ~dp_out;
            next_dm_out = ~dm_out;
        end
    end
    endcase
end


endmodule

