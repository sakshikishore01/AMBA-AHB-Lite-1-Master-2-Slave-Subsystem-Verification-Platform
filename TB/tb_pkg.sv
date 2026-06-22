`timescale 1ns/1ps
package tb_pkg;
    import ahb_pkg::*;

    // ==========================================
    // 1. TRANSACTION
    // ==========================================
    class ahb_transaction;
        rand logic [31:0] start_addr;
        rand logic        write_mode;
        rand logic [31:0] data_stream [4];
        
        constraint c_aligned { start_addr[1:0] == 2'b00; }
        constraint c_regions {
            start_addr inside {[32'h00:32'h0C], [32'h10:32'h1C]};
        }

        function void display(string name);
            $display("[%s] Addr: 0x%8h | Mode: %s | Data: [0x%8h, 0x%8h, 0x%8h, 0x%8h]", 
                     name, start_addr, write_mode ? "WRITE" : "READ", 
                     data_stream[0], data_stream[1], data_stream[2], data_stream[3]);
        endfunction
    endclass : ahb_transaction

    // ==========================================
    // 2. GENERATOR
    // ==========================================
    class ahb_generator;
        mailbox gen2drv;
        int     loop_count;
        event   drv_done;

        function new(mailbox gen2drv, event drv_done);
            this.gen2drv  = gen2drv;
            this.drv_done = drv_done;
        endfunction

        task run();
            repeat(loop_count) begin
                ahb_transaction tx = new();
                if (!tx.randomize()) $error("[GEN] Randomization Failed!");
                tx.display("GENERATOR");
                gen2drv.put(tx);
                @drv_done;
            end
        endtask
    endclass : ahb_generator

    // ==========================================
    // 3. DRIVER
    // ==========================================
    class ahb_driver;
        virtual ahb_if.Master vif;
        mailbox gen2drv;
        event   drv_done;

        function new(virtual ahb_if.Master vif, mailbox gen2drv, event drv_done);
            this.vif      = vif;
            this.gen2drv  = gen2drv;
            this.drv_done = drv_done;
        endfunction

        task run();
            forever begin
                ahb_transaction tx;
                gen2drv.get(tx);
                
                while (!vif.hready) @(posedge vif.clk);

                // Sideband control drives to master unit
                vif.start_addr  <= tx.start_addr;
                vif.write_mode  <= tx.write_mode;
                vif.data_stream <= tx.data_stream;
                vif.start_burst <= 1'b1;

                @(posedge vif.clk);
                vif.start_burst <= 1'b0;

                repeat(4) begin
                    @(posedge vif.clk);
                    while (!vif.hready) @(posedge vif.clk);
                end
                
                #1;
                ->drv_done;
            end
        endtask
    endclass : ahb_driver

    // ==========================================
    // 4. MONITOR
    // ==========================================
    class ahb_monitor;
        virtual ahb_if vif;
        mailbox    mon2scb;

        function new(virtual ahb_if vif, mailbox mon2scb);
            this.vif     = vif;
            this.mon2scb = mon2scb;
        endfunction

        task run();
            forever begin
                @(posedge vif.clk);
                if (vif.htrans == HTRANS_NONSEQ && vif.hready) begin
                    ahb_transaction captured_tx = new();
                    captured_tx.start_addr = vif.haddr;
                    captured_tx.write_mode = vif.hwrite;

                    for (int i = 0; i < 4; i++) begin
                        @(posedge vif.clk);
                        while (!vif.hready) @(posedge vif.clk);
                        
                        if (captured_tx.write_mode)
                            captured_tx.data_stream[i] = vif.hwdata;
                        else
                            captured_tx.data_stream[i] = vif.hrdata;
                    end
                    captured_tx.display("MONITOR DETECTED");
                    mon2scb.put(captured_tx);
                end
            end
        endtask
    endclass : ahb_monitor

    // ==========================================
    // 5. SCOREBOARD
    // ==========================================
    class ahb_scoreboard;
        mailbox mon2scb;
        logic [31:0] ref_mem [32];

        function new(mailbox mon2scb);
            this.mon2scb = mon2scb;
            foreach(ref_mem[i]) ref_mem[i] = 32'h00000000; // Force-match RTL reset state
        endfunction

        task run();
            forever begin
                ahb_transaction tx;
                mon2scb.get(tx);

                if (tx.write_mode) begin
                    logic [31:0] temp_addr = tx.start_addr;
                    for (int i = 0; i < 4; i++) begin
                        ref_mem[temp_addr[6:2]] = tx.data_stream[i];
                        temp_addr += 4;
                    end
                    $display("[SCOREBOARD] Golden Reference Memory Updated.");
                end else begin
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
    endclass : ahb_scoreboard

    // ==========================================
    // 6. ENVIRONMENT CONTAINER
    // ==========================================
    class ahb_environment;
        ahb_generator  gen;
        ahb_driver     drv;
        ahb_monitor    mon;
        ahb_scoreboard scb;

        mailbox gen2drv;
        mailbox mon2scb;
        event   drv_done;

        virtual ahb_if bus_vif;

        function new(virtual ahb_if bus_vif);
            this.bus_vif = bus_vif;
            gen2drv  = new();
            mon2scb  = new();
            
            gen = new(gen2drv, drv_done);
            drv = new(bus_vif.Master, gen2drv, drv_done);
            mon = new(bus_vif, mon2scb);
            scb = new(mon2scb);
        endfunction

        task run(int test_cycles);
            gen.loop_count = test_cycles;
            fork
                gen.run();
                drv.run();
                mon.run();
                scb.run();
            join_any
            #100;
        endtask
    endclass : ahb_environment

endpackage : tb_pkg
