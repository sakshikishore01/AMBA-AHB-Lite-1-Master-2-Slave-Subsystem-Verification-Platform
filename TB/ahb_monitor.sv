class ahb_monitor;
    virtual ahb_if vif; // Looks at the raw interface wires
    mailbox mon2scb;

    function new(virtual ahb_if vif, mailbox mon2scb);
        this.vif     = vif;
        this.mon2scb = mon2scb;
    endfunction

    task run();
        forever begin
            @(posedge vif.clk);
            // Detect when master kicks off a transaction burst
            if (vif.htrans == HTRANS_NONSEQ && vif.hready) begin
                ahb_transaction captured_tx = new();
                captured_tx.start_addr = vif.haddr;
                captured_tx.write_mode = vif.hwrite;

                // Loop through and collect the data payloads for the 4 beats
                for (int i = 0; i < 4; i++) begin
                    @(posedge vif.clk);
                    while (!vif.hready) @(posedge vif.clk); // Wait here if slave holds hready low
                    
                    if (captured_tx.write_mode)
                        captured_tx.data_stream[i] = vif.hwdata; // Capture writes
                    else
                        captured_tx.data_stream[i] = vif.hrdata; // Capture reads
                end
                
                captured_tx.display("MONITOR DETECTED");
                mon2scb.put(captured_tx); // Pass up to scoreboard
            end
        end
    endtask
endclass
