`include "ahb_transaction.sv"
`include "ahb_generator.sv"
`include "ahb_driver.sv"
`include "ahb_monitor.sv"
`include "ahb_scoreboard.sv"

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
        join_any // Stop when generator runs out of transactions
        #100;
    endtask
endclass
