import ahb_pkg::*;

module ahb_system_top (
    ahb_if.Master master_bus_port, // External port connection loop for verification engine
    input logic start_burst, input logic [31:0] start_addr,
    input logic write_mode,   input logic [31:0] data_stream [4]
);

    // Structural Interconnect Wires
    logic hsel_s1, hsel_s2;
    wire [AHB_DATA_WIDTH-1:0] hrdata_s1, hrdata_s2;
    wire hreadyout_s1, hreadyout_s2;

    // 1. Instance of Bursting Master
    ahb_master_burst master_unit (
        .m_bus(master_bus_port),
        .start_burst(start_burst),
        .start_addr(start_addr),
        .write_mode(write_mode),
        .data_stream(data_stream)
    );

    // 2. Instance of Central Routing Matrix
    ahb_interconnect interconnect_unit (
        .clk(master_bus_port.clk), .rst_n(master_bus_port.rst_n),
        .master_haddr(master_bus_port.haddr),
        .master_hrdata(master_bus_port.hrdata),
        .master_hready(master_bus_port.hready),
        .hsel_s1(hsel_s1),          .hsel_s2(hsel_s2),
        .hrdata_s1(hrdata_s1),      .hreadyout_s1(hreadyout_s1),
        .hrdata_s2(hrdata_s2),      .hreadyout_s2(hreadyout_s2)
    );

    // 3. Connect Slave Blocks (Binding the unified interface wrappers)
    ahb_if s1_if_wire (master_bus_port.clk, master_bus_port.rst_n);
    ahb_if s2_if_wire (master_bus_port.clk, master_bus_port.rst_n);

    // Forward master state to internal Slave 1 interface structures
    assign s1_if_wire.haddr  = master_bus_port.haddr;
    assign s1_if_wire.htrans = master_bus_port.htrans;
    assign s1_if_wire.hwrite = master_bus_port.hwrite;
    assign s1_if_wire.hwdata = master_bus_port.hwdata;
    assign s1_if_wire.hready = master_bus_port.hready; // Global status feed
    assign hrdata_s1         = s1_if_wire.hrdata;
    assign hreadyout_s1      = s1_if_wire.hreadyout;   // Capture local output

    // Forward master state to internal Slave 2 interface structures
    assign s2_if_wire.haddr  = master_bus_port.haddr;
    assign s2_if_wire.htrans = master_bus_port.htrans;
    assign s2_if_wire.hwrite = master_bus_port.hwrite;
    assign s2_if_wire.hwdata = master_bus_port.hwdata;
    assign s2_if_wire.hready = master_bus_port.hready; // Global status feed
    assign hrdata_s2         = s2_if_wire.hrdata;
    assign hreadyout_s2      = s2_if_wire.hreadyout;   // Capture local output

    // --- INSTANTIATE BOTH REAL HARDWARE SLAVES NOW ---
    // Slave 1: Real Fast Memory Block (0-wait states)
    ahb_slave_fast slave_fast_inst (.s_bus(s1_if_wire.Slave), .hsel(hsel_s1));

    // Slave 2: Real Slow Peripheral Block (1-wait state injected)
    ahb_slave_slow slave_slow_inst (.s_bus(s2_if_wire.Slave), .hsel(hsel_s2));

endmodule : ahb_system_top
