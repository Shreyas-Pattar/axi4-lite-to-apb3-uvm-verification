`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "apb_seq_item.sv"

class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual apb_if vif;
    uvm_analysis_port #(apb_seq_item) mon_ap;

    function new(input string name = "apb_monitor", input uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(input uvm_phase phase);
        super.build_phase(phase);
        mon_ap = new("mon_ap", this);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("APB_MON_NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    virtual task run_phase(input uvm_phase phase);
        wait (vif.aresetn === 1'b1);
        forever begin
            monitor_transfer();
        end
    endtask

    virtual task monitor_transfer();
        apb_seq_item item;

        // Sample exclusively on access phase completion: PSEL && PENABLE && PREADY
        do @(vif.mon_cb); while (!(vif.mon_cb.psel && vif.mon_cb.penable && vif.mon_cb.pready));

        item = apb_seq_item::type_id::create("mon_apb_item");
        item.paddr   = vif.mon_cb.paddr;
        item.pwrite  = vif.mon_cb.pwrite;
        item.pwdata  = vif.mon_cb.pwdata;
        item.pstrb   = vif.mon_cb.pstrb;
        item.prdata  = vif.mon_cb.prdata;
        item.pslverr = vif.mon_cb.pslverr;

        mon_ap.write(item);
    endtask

endclass

`endif