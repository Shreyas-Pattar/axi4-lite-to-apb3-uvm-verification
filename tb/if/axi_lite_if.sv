`ifndef AXI_LITE_IF_SV
`define AXI_LITE_IF_SV

interface axi_lite_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input logic aclk,
    input logic aresetn
);

    // Write Address Channel
    logic [ADDR_WIDTH-1:0]   awaddr;
    logic [2:0]              awprot;
    logic                    awvalid;
    logic                    awready;

    // Write Data Channel
    logic [DATA_WIDTH-1:0]   wdata;
    logic [(DATA_WIDTH/8)-1:0] wstrb;
    logic                    wvalid;
    logic                    wready;

    // Write Response Channel
    logic [1:0]              bresp;
    logic                    bvalid;
    logic                    bready;

    // Read Address Channel
    logic [ADDR_WIDTH-1:0]   araddr;
    logic [2:0]              arprot;
    logic                    arvalid;
    logic                    arready;

    // Read Data Channel
    logic [DATA_WIDTH-1:0]   rdata;
    logic [1:0]              rresp;
    logic                    rvalid;
    logic                    rready;

    // Master Driver Clocking Block (Synchronous drive with setup margin)
    clocking drv_cb @(posedge aclk);
        default input #1step output #1ns;
        output awaddr, awprot, awvalid;
        input  awready;
        output wdata, wstrb, wvalid;
        input  wready;
        input  bresp, bvalid;
        output bready;
        output araddr, arprot, arvalid;
        input  arready;
        input  rdata, rresp, rvalid;
        output rready;
    endclocking

    // Passive Monitor Clocking Block (Synchronous sampling)
    clocking mon_cb @(posedge aclk);
        default input #1step output #0;
        input awaddr, awprot, awvalid, awready;
        input wdata, wstrb, wvalid, wready;
        input bresp, bvalid, bready;
        input araddr, arprot, arvalid, arready;
        input rdata, rresp, rvalid, rready;
    endclocking

    modport DRV (clocking drv_cb, input aclk, aresetn);
    modport MON (clocking mon_cb, input aclk, aresetn);

endinterface

`endif