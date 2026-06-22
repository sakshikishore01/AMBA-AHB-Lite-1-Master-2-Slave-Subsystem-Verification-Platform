class ahb_scoreboard;
    mailbox mon2scb;
    logic [31:0] ref_mem [32]; // Software reference model memory allocation

    function new(mailbox mon2scb);
        this.mon2scb = mon2scb;
    endfunction

    task run();
        forever begin
            ahb_transaction tx;
            mon2scb.get(tx); // Catch monitored packet

            if (tx.write_mode) begin
                // Update reference memory bank
                logic [31:0] temp_addr = tx.start_addr;
                for (int i = 0; i < 4; i++) begin
                    ref_mem[temp_addr[6:2]] = tx.data_stream[i];
                    temp_addr += 4;
                end
                $display("[SCOREBOARD] Golden Reference Memory Updated.");
            end else begin
                // Compare read outcomes against golden reference model
                logic [31:0] temp_addr = tx.start_addr;
                for (int i = 0; i < 4; i++) begin
                    if (tx.data_stream[i] !== ref_mem[temp_addr[6:2]]) begin
                        $error("[MISMATCH] Addr: 0x%8h | Exp: 0x%8h | Got: 0x%8h", 
                                temp_addr, ref_mem[temp_addr[6:2]], tx.data_stream[i]);
                    end else begin
                        $display("[PASS] Addr: 0x%8h verified perfectly!", temp_addr);
                    end
                    temp_addr += 4;
                end
            end
        end
    endtask
endclass
