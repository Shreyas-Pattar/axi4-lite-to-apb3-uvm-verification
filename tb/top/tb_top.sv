`timescale 1ns / 1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi_lite_if.sv"
`include "apb_if.sv"
`include "axi_to_apb_base_test.sv"

module tb_top;

    // Clock and Reset Signals
    logic aclk;
    logic aresetn;

    // 100 MHz Clock Generation (10.000 ns period)
    initial begin
        aclk = 1'b0;
        forever #5.000 aclk = ~aclk;
    end

    // Reset Generation
    initial begin
        aresetn = 1'b0;
        repeat (10) @(posedge aclk);
        aresetn = 1'b1;
    end

    // Physical Interface Instances
    axi_lite_if #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) axi_if (.aclk(aclk), .aresetn(aresetn));
    apb_if      #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) apb_if (.aclk(aclk), .aresetn(aresetn));

    // Connect Interfaces to DUT (axi_to_apb_bridge from Project 2)
    axi_to_apb_bridge #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32)
    ) dut (
        .aclk          (aclk),
        .aresetn        (aresetn),

        // AXI4-Lite Slave Interface
        .s_axi_awaddr  (axi_if.awaddr),
        .s_axi_awprot  (axi_if.awprot),
        .s_axi_awvalid (axi_if.awvalid),
        .s_axi_awready (axi_if.awready),

        .s_axi_wdata   (axi_if.wdata),
        .s_axi_wstrb   (axi_if.wstrb),
        .s_axi_wvalid  (axi_if.wvalid),
        .s_axi_wready  (axi_if.wready),

        .s_axi_bresp   (axi_if.bresp),
        .s_axi_bvalid  (axi_if.bvalid),
        .s_axi_bready  (axi_if.bready),

        .s_axi_araddr  (axi_if.araddr),
        .s_axi_arprot  (axi_if.arprot),
        .s_axi_arvalid (axi_if.arvalid),
        .s_axi_arready (axi_if.arready),

        .s_axi_rdata   (axi_if.rdata),
        .s_axi_rresp   (axi_if.rresp),
        .s_axi_rvalid  (axi_if.rvalid),
        .s_axi_rready  (axi_if.rready),

        // APB3 Master Interface
        .m_apb_paddr   (apb_if.paddr),
        .m_apb_psel    (apb_if.psel),
        .m_apb_penable (apb_if.penable),
        .m_apb_pwrite  (apb_if.pwrite),
        .m_apb_pwdata  (apb_if.pwdata),
        .m_apb_pstrb   (apb_if.pstrb),
        .m_apb_prdata  (apb_if.prdata),
        .m_apb_pready  (apb_if.pready),
        .m_apb_pslverr (apb_if.pslverr)
    );

    // Register Interfaces and Launch UVM Test
    initial begin
        // Pass virtual interfaces to config_db
        uvm_config_db#(virtual axi_lite_if)::set(null, "uvm_test_top.env.axi_agt*", "vif", axi_if);
        uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.env.apb_agt*", "vif", apb_if);

        // Run the base test
        run_test("axi_to_apb_base_test");
    end

endmodule