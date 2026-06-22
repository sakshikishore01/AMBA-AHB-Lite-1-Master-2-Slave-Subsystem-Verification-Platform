import ahb_pkg::*;

module ahb_slave_fast (
    ahb_if.Slave s_bus,
    input logic  hsel
);

    // Internal Slave Memory Array (4 words deep)
    logic [AHB_DATA_WIDTH-1:0] s_mem [4];
    
    // Control phase pipeline registers
    logic                      w_en_reg;
    logic                      r_en_reg; 
    logic [AHB_ADDR_WIDTH-1:0] addr_reg;

    //Initialize memory to 0 to stop [0xxxxxxxxx] mismatches
    initial begin
        for (int i = 0; i < 4; i++) s_mem[i] = 32'h0;
    end

    // CRITICAL DIFFERENCE: Fast Slave always responds instantly!
    // No wait-state generator state machine here.
    assign s_bus.hreadyout = 1'b1; 

    // Phase Latching Logic (Address Phase -> Data Phase)
    always_ff @(posedge s_bus.clk or negedge s_bus.rst_n) begin
        if (!s_bus.rst_n) begin
            w_en_reg <= 1'b0;
            r_en_reg <= 1'b0;
            addr_reg <= '0;
     end else if (s_bus.hready) begin 
            // Latch Write Enable
            w_en_reg <= hsel && s_bus.hwrite && (s_bus.htrans != HTRANS_IDLE);
            // Latch Read Enable
            r_en_reg <= hsel && !s_bus.hwrite && (s_bus.htrans != HTRANS_IDLE);
            // Latch Address for the Data Phase
            addr_reg <= s_bus.haddr;
        end
    end

    // Memory Write Array Update (Data Phase execution)
    always_ff @(posedge s_bus.clk) begin
        if (w_en_reg && s_bus.hready) begin
            s_mem[addr_reg[3:2]] <= s_bus.hwdata;
        end
    end

    // Memory Read Evaluation (Combinational out to the Mux)
     // We use the latched address (addr_reg) because that represents the address 
    // from the previous cycle.
    assign s_bus.hrdata = (r_en_reg) ? s_mem[addr_reg[3:2]] : 32'h0;

endmodule : ahb_slave_fast
