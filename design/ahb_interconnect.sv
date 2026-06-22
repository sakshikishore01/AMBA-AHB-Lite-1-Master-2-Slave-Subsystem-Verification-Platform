import ahb_pkg::*;

module ahb_interconnect (
    input  logic                      clk,
    input  logic                      rst_n,
    
    // Interface connections from Master Channel
    input  logic [AHB_ADDR_WIDTH-1:0] master_haddr,
    output logic [AHB_DATA_WIDTH-1:0] master_hrdata,
    output logic                      master_hready, // Controls global bus stall
    
    // Decoded Output Selects to Slaves
    output logic                      hsel_s1,
    output logic                      hsel_s2,
    
    // Feedback inputs arriving from individual Slaves
    input  logic [AHB_DATA_WIDTH-1:0] hrdata_s1,    input logic hreadyout_s1,
    input  logic [AHB_DATA_WIDTH-1:0] hrdata_s2,    input logic hreadyout_s2
);

    logic sel_s1_reg, sel_s2_reg;

    // 1. COMBINATIONAL ADDRESS DECODER (Memory Mapping Phase)
    always_comb begin
        hsel_s1 = 1'b0;
        hsel_s2 = 1'b0;
        // Memory Map: Slave 1 (0x00 to 0x0F) | Slave 2 (0x10 to 0x1F)
        if (master_haddr >= 32'h0000_0000 && master_haddr <= 32'h0000_000F) begin
            hsel_s1 = 1'b1;
        end else if (master_haddr >= 32'h0000_0010 && master_haddr <= 32'h0000_001F) begin
            hsel_s2 = 1'b1;
        end
    end

    // 2. THE PIPELINE ROUTE REGISTER LAYER (Aligns Selection to Data Phase)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_s1_reg <= 1'b0;
            sel_s2_reg <= 1'b0;
        end else if (master_hready) begin // Only shift tracking route if slave cleared stall
            sel_s1_reg <= hsel_s1;
            sel_s2_reg <= hsel_s2;
        end
    end

   // 3. THE DATA RESPONSE CHANNEL MULTIPLEXER (FIXED: Explicitly routes signals)
    always_comb begin
        if (sel_s2_reg) begin
            master_hrdata = hrdata_s2;
            master_hready = hreadyout_s2;
        end else if (sel_s1_reg) begin
            master_hrdata = hrdata_s1;
            master_hready = hreadyout_s1;
        end else begin
            master_hrdata = '0;
            master_hready = 1'b1; // Default High keeps the AHB pipeline from freezing up when idle
        end
    end
endmodule : ahb_interconnect
