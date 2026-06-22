class ahb_driver;
    virtual ahb_if.Master vif; // Virtual interface to drive hardware pins
    mailbox gen2drv;
    event drv_done;

    function new(virtual ahb_if.Master vif, mailbox gen2drv, event drv_done);
        this.vif     = vif;
        this.gen2drv = gen2drv;
        this.drv_done = drv_done;
    endfunction

    task run();
        forever begin
            ahb_transaction tx;
            gen2drv.get(tx); // Pull packet out of mailbox
            
            // Wait until bus is ready before launching address phase
            while (!vif.hready) @(posedge vif.clk);

            // Drive sideband structural configurations into the top shell
            // (Simulating an external system command to our Master unit)
            vif.start_addr  <= tx.start_addr;
            vif.write_mode  <= tx.write_mode;
            vif.data_stream <= tx.data_stream;
            vif.start_burst <= 1'b1;

            @(posedge vif.clk);
            vif.start_burst <= 1'b0; // Pull high pulse back down

            // Wait until Master finishes its 4-beat burst state machine loop
            // tracking via cross-module reference or internal interface indicators
            repeat(4) begin
                @(posedge vif.clk);
                while (!vif.hready) @(posedge vif.clk); // Keep loop extended if slave injects stall wait-state
            end
            
            #1; // Minor evaluation delta delay
            ->drv_done; // Trigger handshake event back to Generator
        end
    endtask
