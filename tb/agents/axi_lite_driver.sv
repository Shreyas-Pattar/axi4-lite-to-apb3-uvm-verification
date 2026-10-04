`ifndef AXI_LITE_DRIVER_SV
`define AXI_LITE_DRIVER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "axi_lite_seq_item.sv"

class axi_lite_driver extends uvm_driver #(axi_lite_seq_item);
    `uvm_component_utils(axi_lite_driver)

    virtual axi_lite_if vif;

    function new(input string name = "axi_lite_driver", input uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(input uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("DRV_NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    virtual task run_phase(input uvm_phase phase);
        reset_signals();

        wait (vif.aresetn === 1'b1);
        @(vif.drv_cb);

        forever begin
            seq_item_port.get_next_item(req);
            if (req.op == AXI_WRITE) begin
                drive_write(req);
            end else begin
                drive_read(req);
            end
            seq_item_port.item_done();
        end
    endtask

    virtual task reset_signals();
        wait (vif.aresetn === 1'b0);
        vif.drv_cb.awaddr  <= '0;
        vif.drv_cb.awprot  <= '0;
        vif.drv_cb.awvalid <= 1'b0;
        vif.drv_cb.wdata   <= '0;
        vif.drv_cb.wstrb   <= '0;
        vif.drv_cb.wvalid  <= 1'b0;
        vif.drv_cb.bready  <= 1'b0;
        vif.drv_cb.araddr  <= '0;
        vif.drv_cb.arprot  <= '0;
        vif.drv_cb.arvalid <= 1'b0;
        vif.drv_cb.rready  <= 1'b0;
    endtask

    virtual task drive_write(input axi_lite_seq_item item);
        repeat (item.addr_delay) @(vif.drv_cb);

        // Drive Address and Data Channels concurrently
        vif.drv_cb.awaddr  <= item.addr;
        vif.drv_cb.awprot  <= 3'b000;
        vif.drv_cb.awvalid <= 1'b1;

        vif.drv_cb.wdata   <= item.data;
        vif.drv_cb.wstrb   <= item.strb;
        vif.drv_cb.wvalid  <= 1'b1;
        vif.drv_cb.bready  <= 1'b1;

        // Wait for Address & Data Handshakes
        fork
            begin
                do @(vif.drv_cb); while (!vif.drv_cb.awready);
                vif.drv_cb.awvalid <= 1'b0;
            end
            begin
                do @(vif.drv_cb); while (!vif.drv_cb.wready);
                vif.drv_cb.wvalid <= 1'b0;
            end
        join

        // Wait for Write Response
        do @(vif.drv_cb); while (!vif.drv_cb.bvalid);
        item.resp = vif.drv_cb.bresp;
        vif.drv_cb.bready <= 1'b0;
    endtask

    virtual task drive_read(input axi_lite_seq_item item);
        repeat (item.addr_delay) @(vif.drv_cb);

        // Drive Read Address Channel
        vif.drv_cb.araddr  <= item.addr;
        vif.drv_cb.arprot  <= 3'b000;
        vif.drv_cb.arvalid <= 1'b1;
        vif.drv_cb.rready  <= 1'b1;

        do @(vif.drv_cb); while (!vif.drv_cb.arready);
        vif.drv_cb.arvalid <= 1'b0;

        // Wait for Read Data Response
        do @(vif.drv_cb); while (!vif.drv_cb.rvalid);
        item.rdata = vif.drv_cb.rdata;
        item.resp  = vif.drv_cb.rresp;
        vif.drv_cb.rready <= 1'b0;
    endtask

endclass

`endif