package ahb_pkg;

    // Strong Enumerations for Protocol Signaling
    typedef enum logic [1:0] {
        HTRANS_IDLE   = 2'b00,
        HTRANS_BUSY   = 2'b01,
        HTRANS_NONSEQ = 2'b10,
        HTRANS_SEQ    = 2'b11
    } htrans_e;

    typedef enum logic [2:0] {
        HBURST_SINGLE = 3'b000,
        HBURST_INCR4  = 3'b011
    } hburst_e;

    // System Parameters
    localparam int AHB_DATA_WIDTH = 32;
    localparam int AHB_ADDR_WIDTH = 32;

endpackage : ahb_pkg
