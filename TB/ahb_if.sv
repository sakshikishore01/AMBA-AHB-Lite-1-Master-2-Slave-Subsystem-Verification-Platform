`timescale 1ns/1ps

interface ahb_if (input logic clk, input logic rst_n);
    import ahb_pkg::*;

    // 1. Standard AMBA AHB Protocol Wires
    logic [AHB_ADDR_WIDTH-1:0] haddr;
    logic                      hwrite;
    htrans_e                   htrans;
    hburst_e                   hburst;
    logic [AHB_DATA_WIDTH-1:0] hwdata;
    logic [AHB_DATA_WIDTH-1:0] hrdata;
    logic                      hready;    // Global Bus Ready Feedback
    logic                      hreadyout; // Local Per-Slave Ready Feedback
    
    // 2. Testbench Sideband Control Signals 
    logic                      start_burst;
    logic [AHB_ADDR_WIDTH-1:0] start_addr;
    logic                      write_mode;
    logic [AHB_DATA_WIDTH-1:0] data_stream [4];

    // Master Modport View (Crucial: Driver accesses sidebands here as output)
    modport Master (
        input  clk, rst_n, hready, hrdata,
        output haddr, hwrite, htrans, hburst, hwdata,
        output start_burst, start_addr, write_mode, data_stream
    );

    // Slave Modport View 
    modport Slave (
        input  clk, rst_n, hready, haddr, hwrite, htrans, hburst, hwdata,
        output hrdata, hreadyout
    );

endinterface : ahb_if
