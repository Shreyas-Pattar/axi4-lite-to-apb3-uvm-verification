`ifndef AXI_LITE_AGENT_SV
`define AXI_LITE_AGENT_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi_lite_seq_item.sv"
`include "axi_lite_driver.sv"
`include "axi_lite_monitor.sv"

class axi_lite_agent extends uvm_agent;
    `uvm_component_utils(axi_lite_agent)

    // Agent Sub-components
    uvm_sequencer #(axi_lite_seq_item) sqr;
    axi_lite_driver                    drv;
    axi_lite_monitor                   mon;

    // TLM Analysis Port forwarded from monitor
    uvm_analysis_port #(axi_lite_seq_item) ap;

    function new(input string name = "axi_lite_agent", input uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(input uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);

        // Monitor is always present (Active & Passive)
        mon = axi_lite_monitor::type_id::create("mon", this);

        // Driver and Sequencer built only in ACTIVE mode
        if (get_is_active() == UVM_ACTIVE) begin
            sqr = uvm_sequencer#(axi_lite_seq_item)::type_id::create("sqr", this);
            drv = axi_lite_driver::type_id::create("drv", this);
        end
    endfunction

    virtual function void connect_phase(input uvm_phase phase);
        super.connect_phase(phase);

        // Connect monitor analysis port to agent analysis port
        mon.mon_ap.connect(this.ap);

        // Connect driver to sequencer in ACTIVE mode
        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass

`endif