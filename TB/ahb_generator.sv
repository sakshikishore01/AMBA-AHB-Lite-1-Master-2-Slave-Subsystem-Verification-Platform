class ahb_generator;
    mailbox gen2drv;
    int  loop_count;
    event drv_done; // Event handshake to slow down generation

    function new(mailbox gen2drv, event drv_done);
        this.gen2drv   = gen2drv;
        this.drv_done  = drv_done;
    endfunction

    task run();
        repeat(loop_count) begin
            ahb_transaction tx = new();
            if (!tx.randomize()) $error("[GEN] Randomization Failed!");
            tx.display("GENERATOR");
            gen2drv.put(tx); // Push transaction into the mailbox for the driver
            @drv_done;       // Wait until driver finishes execution before making a new one
        end
    endtask
endclass
