interface apb_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input logic pclk,
    input logic presetn
);
    logic psel;
    logic penable;
    logic pwrite;
    logic [ADDR_WIDTH-1:0] paddr;
    logic [DATA_WIDTH-1:0] pwdata;
    logic pready;
    logic pslverr;
    logic [DATA_WIDTH-1:0] prdata;

    clocking cb_driver @(posedge pclk);
        default input #1step output #1ns;
        output psel, penable, pwrite, paddr, pwdata;
        input  pready, pslverr, prdata;
    endclocking

    clocking cb_monitor @(posedge pclk);
        default input #1step;
        input psel, penable, pwrite, paddr, pwdata, pready, pslverr, prdata;
    endclocking

    modport driver_mp  (clocking cb_driver,  input pclk, presetn);
    modport monitor_mp (clocking cb_monitor, input pclk, presetn);
endinterface