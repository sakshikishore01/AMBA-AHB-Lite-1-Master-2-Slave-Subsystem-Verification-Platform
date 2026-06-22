import ahb_pkg::*;

class ahb_transaction;
    rand logic [31:0] start_addr;
    rand logic        write_mode;
    rand logic [31:0] data_stream [4]; // 4 data words for INCR4

    // Word-aligned address constraint
    constraint c_aligned { start_addr[1:0] == 2'b00; }

    // Keep transactions within legal slave memory boundaries
    constraint c_regions {
        start_addr inside {[32'h00:32'h0C], [32'h10:32'h1C]};
    }

    function void display(string name);
        $display("[%s] Addr: 0x%8h | Mode: %s | Data: [0x%8h, 0x%8h, 0x%8h, 0x%8h]", 
                 name, start_addr, write_mode ? "WRITE" : "READ", 
                 data_stream[0], data_stream[1], data_stream[2], data_stream[3]);
    endfunction
endclass
