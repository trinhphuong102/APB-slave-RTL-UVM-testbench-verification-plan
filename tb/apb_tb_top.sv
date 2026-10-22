`include "uvm_macros.svh"

module tb_top;
    import uvm_pkg::*;
    import apb_pkg::*;
    logic pclk;
    logic presetn;

    initial begin
        pclk = 0;
        forever #5 pclk = ~pclk; 
    end

    initial begin
        presetn = 0;
        #20 presetn = 1;
    end

    apb_if vif(pclk, presetn);

    async_apb_slave dut (
        .pclk    (vif.pclk),
        .presetn (vif.presetn),
        .paddr   (vif.paddr),
        .pwrite  (vif.pwrite),
        .psel    (vif.psel),
        .penable (vif.penable),
        .pwdata  (vif.pwdata),
        .prdata  (vif.prdata),
        .pready  (vif.pready),
        .pslverr (vif.pslverr)
    );

    initial begin
        uvm_config_db#(virtual apb_if.driver_mp )::set(null, "uvm_test_top.env.agent.driver",  "vif", vif.driver_mp);
        uvm_config_db#(virtual apb_if.monitor_mp)::set(null, "uvm_test_top.env.agent.monitor", "vif", vif.monitor_mp);
        run_test("apb_test"); 
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end

endmodule