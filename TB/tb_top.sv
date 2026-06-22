`timescale 1ns/1ps

module tb_top;
    import ahb_pkg::*;
    import tb_pkg::*; // Pulls in all our DV classes safely

    logic clk = 0;
    logic rst_n = 0;

    // Interface Instance
    ahb_if bus_if(clk, rst_n);

    // Structural DUT Top Instance
    ahb_system_top dut (
        .master_bus_port(bus_if.Master),
        .start_burst(bus_if.start_burst),
        .start_addr(bus_if.start_addr),
        .write_mode(bus_if.write_mode),
        .data_stream(bus_if.data_stream)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // Pointer handle for verification environment object
    ahb_environment env;

    initial begin
        #15 rst_n = 1;
        #10;
        
        env = new(bus_if);
        
        $display("[STATUS] Starting Class-Based Constrained Randomization Test...");
        env.run(10); // Execute 10 randomized burst sequences
        
        $display("[STATUS] All class-based checks complete.");
        $finish;
    end

    initial begin
        $shm_open("waves.shm");
        $shm_probe("ACSTF");
    end
endmodule
