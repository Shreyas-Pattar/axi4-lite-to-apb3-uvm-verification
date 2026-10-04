`ifndef APB_IF_SV
`define APB_IF_SV

interface apb_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input logic aclk,
    input logic aresetn
);

    logic [ADDR_WIDTH-1:0]     paddr;
    logic                      psel;
    logic                      penable;
    logic                      pwrite;
    logic [DATA_WIDTH-1:0]     pwdata;
    logic [(DATA_WIDTH/8)-1:0] pstrb;
    logic [DATA_WIDTH-1:0]     prdata;
    logic                      pready;
    logic                      pslverr;

    // Reactive Slave Driver Clocking Block
    clocking slv_cb @(posedge aclk);
        default input #1step output #1ns;
        input  paddr, psel, penable, pwrite, pwdata, pstrb;
        output prdata, pready, pslverr;
    endclocking

    // Passive Monitor Clocking Block
    clocking mon_cb @(posedge aclk);
        default input #1step output #0;
        input paddr, psel, penable, pwrite, pwdata, pstrb;
        input prdata, pready, pslverr;
    endclocking

    modport SLV (clocking slv_cb, input aclk, aresetn);
    modport MON (clocking mon_cb, input aclk, aresetn);

endinterface

`endif