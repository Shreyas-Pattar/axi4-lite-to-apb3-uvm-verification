`ifndef AXI_LITE_MONITOR_SV
`define AXI_LITE_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "axi_lite_seq_item.sv"

class axi_lite_monitor extends uvm_monitor;
    `uvm_component_utils(axi_lite_monitor)

    virtual axi_lite_if vif;
    uvm_analysis_port #(axi_lite_seq_item) mon_ap;

    function new(input string name = "axi_lite_monitor", input uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(input uvm_phase phase);
        super.build_phase(phase);
        mon_ap = new("mon_ap", this);
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MON_NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    virtual task run_phase(input uvm_phase phase);
        wait (vif.aresetn === 1'b1);
        @(vif.mon_cb);

        forever begin
            @(vif.mon_cb);
            // Check for completed Write Transaction (BRESP handshake)
            if (vif.mon_cb.bvalid && vif.mon_cb.bready) begin
                axi_lite_seq_item item = axi_lite_seq_item::type_id::create("mon_wr_item");
                item.op   = AXI_WRITE;
                item.addr = vif.mon_cb.awaddr; // Sample registered address
                item.data = vif.mon_cb.wdata;
                item.strb = vif.mon_cb.wstrb;
                item.resp = vif.mon_cb.bresp;
                mon_ap.write(item);
            end
            // Check for completed Read Transaction (RDATA handshake)
            else if (vif.mon_cb.rvalid && vif.mon_cb.rready) begin
                axi_lite_seq_item item = axi_lite_seq_item::type_id::create("mon_rd_item");
                item.op    = AXI_READ;
                item.addr  = vif.mon_cb.araddr;
                item.rdata = vif.mon_cb.rdata;
                item.resp  = vif.mon_cb.rresp;
                mon_ap.write(item);
            end
        end
    endtask

endclass

`endif