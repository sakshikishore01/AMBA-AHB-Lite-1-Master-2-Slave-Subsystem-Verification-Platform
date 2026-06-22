import ahb_pkg::*;

module ahb_slave_slow (
    ahb_if.Slave s_bus,
    input logic  hsel
);

    logic [AHB_DATA_WIDTH-1:0] s_mem [4];   // 4-word internal memory matrix
    logic                      wait_state;
    logic                      w_en_reg;
    logic                      r_en_reg;
    logic [AHB_ADDR_WIDTH-1:0] addr_reg;


    //Initialize internal memory to 0 to prevent scoreboard 0xxxxxxxxx mismatches
    initial begin
        for (int i = 0; i < 4; i++) begin
            s_mem[i] = 32'h0000_0000;
        end
    end

    // Stalling Engine Logic
    always_ff @(posedge s_bus.clk or negedge s_bus.rst_n) begin
        if (!s_bus.rst_n) begin
            wait_state <= 1'b0;
        end else begin
            if (hsel && (s_bus.htrans == HTRANS_NONSEQ || s_bus.htrans == HTRANS_SEQ) && !wait_state && s_bus.hready) begin
                wait_state <= 1'b1; // Drop read/write gate for 1 clock pulse
            end else begin
                wait_state <= 1'b0; // Release stall
            end
        end
    end

    assign s_bus.hreadyout = ~wait_state;

  // Phase Latching Logic (Controls Address Phase -> Data Phase conversion)
    always_ff @(posedge s_bus.clk or negedge s_bus.rst_n) begin
        if (!s_bus.rst_n) begin
            w_en_reg <= 1'b0;
            r_en_reg <= 1'b0;
            addr_reg <= '0;
        end else if (s_bus.hreadyout && s_bus.hready) begin // Only latch when transaction phases update
            w_en_reg <= hsel && s_bus.hwrite && (s_bus.htrans != HTRANS_IDLE);
            r_en_reg <= hsel && !s_bus.hwrite && (s_bus.htrans != HTRANS_IDLE);
            addr_reg <= s_bus.haddr;
        end else if (s_bus.hreadyout && !s_bus.hready) begin
            // Clear pipeline registers if another slave stalls the bus
            w_en_reg <= 1'b0;
            r_en_reg <= 1'b0;
        end
    end

    // Memory Write Array
    always_ff @(posedge s_bus.clk) begin
        if (w_en_reg && s_bus.hready) begin
            s_mem[addr_reg[3:2]] <= s_bus.hwdata;
        end
    end

    // Memory Read Evaluation
    // Uses r_en_reg and the registered address tracking channel to hold read data 
    // stable across the injected wait states.
    assign s_bus.hrdata = (r_en_reg) ? s_mem[addr_reg[3:2]] : 32'h0000_0000;

endmodule : ahb_slave_slow
