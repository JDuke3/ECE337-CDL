`timescale 1ns / 10ps

module ahb_lite_subordinate (
    input clk, n_rst,
    input logic hsel,
    input logic [3:0] haddr,
    input logic [1:0] htrans,
    input logic [1:0] hsize,
    input logic hwrite,
    input logic [31:0] hwdata,
    input logic [2:0] hburst,

    input logic [3:0] rx_packet,
    input logic rx_data_ready,
    input logic rx_transfer_active,
    input logic rx_error,
    input logic tx_transfer_active,
    input logic tx_error,
    input logic [7:0] rx_data,
    input logic [6:0] buffer_occupancy,

    output logic [31:0] hrdata,
    output logic hready,
    output logic hresp,

    output logic [7:0] tx_data,
    output logic [3:0] tx_packet,
    output logic get_rx_data,
    output logic store_tx_data,
    output logic clear,
    output logic d_mode
);
    //Packet Type
    localparam OUT = 4'b0001;
    localparam IN = 4'b1001;
    localparam DATA0 = 4'b0011;
    localparam DATA1 = 4'b1011;
    localparam ACK = 4'b0010;
    localparam NAK = 4'b1010;
    localparam STALL = 4'b1110;

    // Internal Registers Address
    localparam DATA_BUFFER_ADDR = 4'h0;
    localparam STATUS_ADDR = 4'h4;
    localparam ERROR_ADDR = 4'h6;
    localparam BUFFER_OCCU_ADDR = 4'h8;
    localparam TX_CTRL_ADDR = 4'hC;
    localparam FLUSH_CTRL_ADDR = 4'hD;

    // Internal Register Regs
    logic [31:0] data_buffer_reg;
    logic [15:0] status_reg;
    logic [15:0] error_reg;
    logic [7:0] buffer_occu_reg;
    logic [7:0] tx_ctrl_reg;
    logic [7:0] flush_ctrl_reg;

    // Pipelined AHB signals
    logic [3:0] haddr_pipeline;
    logic [3:0] haddr_pipeline_2;
    logic hwrite_pipeline;
    logic [1:0] hsize_pipeline;
    logic [1:0] hsize_pipeline_2;
    logic valid_access_pipeline;
    logic [31:0] hwdata_pipeline;
    logic raw_pipeline;

    // Verify signals
    logic valid_address;
    logic valid_write;
    logic valid_access;
    logic raw;


    //tx packet fix
    logic tx_transfer_hold;

    typedef enum logic [3:0] {
        IDLE,
        ADDR_PHASE,
        DATA_PHASE_B1,
        DATA_PHASE_B2,
        DATA_PHASE_B3,
        DATA_PHASE_B4,
        ERROR_PHASE1,
        ERROR_PHASE2
    } state_t;

    state_t current_state, next_st;
    logic error;

    assign d_mode = hwrite_pipeline;

    always_comb begin : Verification
        valid_address = 0;
        valid_write = 0;

        if (hsize == 2) begin
            valid_address = (haddr == DATA_BUFFER_ADDR);
        end else if (hsize == 1) begin
            valid_address = ((haddr == DATA_BUFFER_ADDR) ||
                            (haddr == DATA_BUFFER_ADDR + 1) ||
                            (haddr == DATA_BUFFER_ADDR + 2) ||
                            (haddr == STATUS_ADDR) ||
                            (haddr == ERROR_ADDR));
        end else begin
            valid_address = (haddr != 4'h9) &&
                            (haddr != 4'hA) && 
                            (haddr != 4'hB) &&
                            (haddr != 4'hE) &&
                            (haddr != 4'hF);  
        end
        //Valid Write Verification
        valid_write =   (haddr == DATA_BUFFER_ADDR) ||
                        (haddr == DATA_BUFFER_ADDR + 1) ||
                        (haddr == DATA_BUFFER_ADDR + 2) ||
                        (haddr == DATA_BUFFER_ADDR + 3) ||
                        (haddr == TX_CTRL_ADDR) ||
                        (haddr == FLUSH_CTRL_ADDR);

        valid_access = hsel && (htrans == 2) && (hsize != 3) && valid_address && (~hwrite | valid_write);

        error = hsel && (htrans == 2) && (~valid_address | (hwrite & ~valid_write) | (hsize == 3));

        //Read/Write Enable
        raw =   ((haddr_pipeline != DATA_BUFFER_ADDR) &&
                (haddr_pipeline != (DATA_BUFFER_ADDR + 1)) &&
                (haddr_pipeline != (DATA_BUFFER_ADDR + 2)) &&
                (haddr_pipeline != (DATA_BUFFER_ADDR + 3))) &&
                (valid_access && ~hwrite) &&
                (valid_access_pipeline && hwrite_pipeline) &&
                (haddr == haddr_pipeline);
    end

    // Data Buffer FSM

    always_ff @(posedge clk, negedge n_rst ) begin : UpdateFSM
        if (!n_rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_st;
        end
    end

    always_comb begin : NextStateLogic
        next_st = current_state;

        case (current_state)
            IDLE: begin
                if (valid_access && 
                ((haddr == DATA_BUFFER_ADDR) || 
                (haddr == DATA_BUFFER_ADDR + 1) ||
                (haddr == DATA_BUFFER_ADDR + 2) ||
                (haddr == DATA_BUFFER_ADDR + 3))) begin
                    next_st = ADDR_PHASE;
                end else if (error) begin
                    next_st = ERROR_PHASE1;
                end
            end 

            ADDR_PHASE: begin
                if (valid_access_pipeline) begin
                    next_st = DATA_PHASE_B1;
                end
            end 

            ERROR_PHASE1: next_st = ERROR_PHASE2;

            ERROR_PHASE2: next_st = IDLE;

            DATA_PHASE_B1: if (hsize_pipeline == 0) begin
                next_st = IDLE;
            end else begin
                next_st = DATA_PHASE_B2;
            end

            DATA_PHASE_B2: 
            if (hsize_pipeline == 2'b10) begin
                next_st = DATA_PHASE_B3;
            end else begin
                next_st = IDLE;
            end

            DATA_PHASE_B3: next_st = DATA_PHASE_B4;

            DATA_PHASE_B4: next_st = IDLE;

            default: next_st = IDLE;
        endcase
    end


    // Output Logic
    always_comb begin : FSM_Output_Logic
        hready = 1;
        hresp = 0;
        get_rx_data = 0;
        store_tx_data = 0;
        tx_data = 0;
        data_buffer_reg = 0; 

        case (current_state)
            IDLE: begin
                hready = 1;
                hresp = 0;
                if (clear) begin
                    data_buffer_reg = 0;
                end
            end

            ADDR_PHASE: begin
                hready = 0;
                hresp = 0;
                if (hwrite_pipeline) begin
                    data_buffer_reg = hwdata;
                end
            end
            
            ERROR_PHASE1: begin
                hresp = 1;
                hready = 0;
            end

            ERROR_PHASE2: begin
                hresp = 1;
                hready = 1;
            end

            DATA_PHASE_B1: begin
                if (hsize_pipeline != 0) begin
                    hready = 0;
                end

                if (hwrite_pipeline) begin
                    // Write
                    case (haddr_pipeline)
                        DATA_BUFFER_ADDR: begin
                            store_tx_data = 1;
                            tx_data = data_buffer_reg[7:0];
                        end
                        DATA_BUFFER_ADDR + 1: begin
                            store_tx_data = 1;
                            tx_data = data_buffer_reg[15:8];
                        end
                        DATA_BUFFER_ADDR + 2: begin
                            store_tx_data = 1;
                            tx_data = data_buffer_reg[23:16];
                        end
                        DATA_BUFFER_ADDR + 3: begin
                            store_tx_data = 1;
                            tx_data = hwdata_pipeline[31:24];
                        end
                    endcase
                end else begin
                    // Read
                    case (haddr_pipeline)
                        DATA_BUFFER_ADDR: begin
                            get_rx_data = 1;
                            data_buffer_reg[7:0] = rx_data;
                        end
                        DATA_BUFFER_ADDR + 1: begin
                            get_rx_data = 1;
                            data_buffer_reg[15:8] = rx_data;
                        end
                        DATA_BUFFER_ADDR + 2: begin
                            get_rx_data = 1;
                            data_buffer_reg[23:16] = rx_data;
                        end
                        DATA_BUFFER_ADDR + 3: begin
                            get_rx_data = 1;
                            data_buffer_reg[31:24] = rx_data;
                        end
                    endcase
                end
            end

            DATA_PHASE_B2: begin
                if (hsize_pipeline != 1) begin
                    hready = 0;
                end

                if (hwrite_pipeline) begin
                    // Write
                    case (haddr_pipeline)
                        DATA_BUFFER_ADDR: begin
                            store_tx_data = 1;
                            tx_data = data_buffer_reg[15:8];
                        end
                        DATA_BUFFER_ADDR + 1: begin
                            store_tx_data = 1;
                            tx_data = data_buffer_reg[23:16];
                        end
                        DATA_BUFFER_ADDR + 2: begin
                            store_tx_data = 1;
                            tx_data = data_buffer_reg[31:24];
                        end
                    endcase
                end else begin
                    // Read
                    case (haddr_pipeline)
                        DATA_BUFFER_ADDR: begin
                            get_rx_data = 1;
                            data_buffer_reg[15:8] = rx_data;
                        end
                        DATA_BUFFER_ADDR + 1: begin
                            get_rx_data = 1;
                            data_buffer_reg[23:16] = rx_data;
                        end
                        DATA_BUFFER_ADDR + 2: begin
                            get_rx_data = 1;
                            data_buffer_reg[31:24] = rx_data;
                        end
                    endcase
                end
            end

            DATA_PHASE_B3: begin
                hready = 0;

                if (hwrite_pipeline) begin
                    // Write
                    case (haddr_pipeline)
                        DATA_BUFFER_ADDR: begin
                            store_tx_data = 1;
                            tx_data = data_buffer_reg[23:16];
                        end
                    default : ;
                    endcase
                end else begin
                    // Read
                    case (haddr_pipeline)
                        DATA_BUFFER_ADDR: begin
                            get_rx_data = 1;
                            data_buffer_reg[23:16] = rx_data;
                        end
                        default : ;
                    endcase
                end
            end

            DATA_PHASE_B4: begin
                hready = 0;

                if (hwrite_pipeline) begin
                    // Write
                    case (haddr_pipeline)
                        DATA_BUFFER_ADDR: begin
                            store_tx_data = 1;
                            tx_data = data_buffer_reg[31:24];
                        end
                        default : ;
                    endcase
                end else begin
                    // Read
                    case (haddr_pipeline)
                        DATA_BUFFER_ADDR: begin
                            get_rx_data = 1;
                            data_buffer_reg[31:24] = rx_data;
                        end
                        default : ;
                    endcase
                end
            end
            
            default: begin
                hready = 1;
                hresp = 0;
                get_rx_data = 0;
                store_tx_data = 0;
                tx_data = 0; 
                data_buffer_reg = 0; 
            end
        endcase
    end

    // Update Internal Registers
    always_comb begin : UpdateRegisters
        // Status Reg
        status_reg[0] = rx_data_ready;
        status_reg[1] = (rx_packet == IN);
        status_reg[2] = (rx_packet == OUT);
        status_reg[3] = (rx_packet == ACK);
        status_reg[4] = (rx_packet == DATA0);
        status_reg[5] = (rx_packet == DATA1);
        status_reg[7:6] = 2'b00;
        status_reg[8] = rx_transfer_active;
        status_reg[9] = tx_transfer_active;
        status_reg[15:10] = 6'b0;

        // Error Reg
        error_reg[0] = rx_error;
        error_reg[7:1] = 0;
        error_reg[8] = tx_error;
        error_reg[15:9] = 0;

        // Buffer Occu Reg
        buffer_occu_reg[6:0] = buffer_occupancy;
        buffer_occu_reg[7] = 0;

        // Tx_Packet
        case(tx_ctrl_reg)
            8'd1: tx_packet = DATA0;
            8'd2: tx_packet = DATA1;
            8'd3: tx_packet = ACK;
            8'd4: tx_packet = NAK;
            8'd5: tx_packet = STALL;
            default: tx_packet = 4'b0000;
        endcase

        // Flush
        clear = flush_ctrl_reg[0];
    end

    // Update Synchronous Registers
    always_ff @(posedge clk, negedge n_rst ) begin : UpdateSynchronous
        if (!n_rst) begin
            tx_ctrl_reg <= 0;
            flush_ctrl_reg <= 0;
            tx_transfer_hold <= 0;
        end else begin

            // Clear the Reg after the packet is sent OR after the buffer is cleared
            if (tx_ctrl_reg != 0 && !tx_transfer_active && !tx_transfer_hold)
                tx_ctrl_reg <= 0;

            if (flush_ctrl_reg != 0)
                flush_ctrl_reg <= 0;

            // Update the Registers if write
            if (valid_access_pipeline && hwrite_pipeline && haddr_pipeline == TX_CTRL_ADDR) begin
                tx_transfer_hold <= 1;
                tx_ctrl_reg <= hwdata[7:0];
            end
            else begin
                tx_transfer_hold <= 0;
            end
            if (valid_access_pipeline && hwrite_pipeline && haddr_pipeline == FLUSH_CTRL_ADDR)
                flush_ctrl_reg <= hwdata[15:8];

            
        end
    end


    // Reading Logic
    always_comb begin
        hrdata = 0;

        //RAW
        if (raw_pipeline) begin
            hrdata = hwdata_pipeline;
        end

        //Normal Read
        else if (valid_access_pipeline && !hwrite_pipeline) begin
            case (haddr_pipeline)
            STATUS_ADDR: begin
                if (hsize_pipeline == 1) // 2-byte read
                    hrdata = {16'h0, status_reg};
                else // 1-byte read from lower byte
                    hrdata = {24'h0, status_reg[7:0]};
            end
            
            STATUS_ADDR + 1: begin
                if (hsize_pipeline == 0) // 1-byte read from upper byte
                    hrdata = {24'b0, status_reg[15:8]};
            end
            
            ERROR_ADDR: begin
                if (hsize_pipeline == 1) // 2-byte read
                    hrdata = {16'b0, error_reg};
                else // 1-byte read from lower byte
                    hrdata = {24'b0, error_reg[7:0]};
            end
            
            ERROR_ADDR + 1: begin
                if (hsize_pipeline == 1) // 1-byte read from upper byte
                    hrdata = {24'b0, error_reg[15:8]};
            end

            BUFFER_OCCU_ADDR: begin
                if (hsize_pipeline == 0)
                    hrdata = {24'b0, buffer_occu_reg};
            end

            TX_CTRL_ADDR: begin
                if (hsize_pipeline == 0) begin
                    hrdata =  {24'b0, tx_ctrl_reg};
                end
            end

            FLUSH_CTRL_ADDR: begin
                if (hsize_pipeline == 0) begin
                    hrdata =  {24'b0, flush_ctrl_reg};
                end
            end

            DATA_BUFFER_ADDR, DATA_BUFFER_ADDR + 1, 
            DATA_BUFFER_ADDR + 2, DATA_BUFFER_ADDR + 3: begin
                hrdata = data_buffer_reg;
            end

            endcase
        end
    end

    //Pipeline Registers
    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            hwrite_pipeline <= 0;
            haddr_pipeline <= 0;
            haddr_pipeline_2 <= 0;
            hsize_pipeline <= 0; 
            hsize_pipeline_2 <= 0;
            valid_access_pipeline <= 0;
            raw_pipeline <= 0;
            hwdata_pipeline <= 0;
        end else if (hready) begin
            hwrite_pipeline <= hwrite;
            haddr_pipeline <= haddr;
            haddr_pipeline_2 <= haddr_pipeline;
            hsize_pipeline <= hsize;
            hsize_pipeline_2 <= hsize_pipeline;
            valid_access_pipeline <= valid_access;
            raw_pipeline <= raw;
            hwdata_pipeline <= hwdata;
        end
    end

endmodule

/* verilator coverage_on */
