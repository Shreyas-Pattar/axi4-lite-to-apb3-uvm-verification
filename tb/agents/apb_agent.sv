`ifndef APB_AGENT_SV
`define APB_AGENT_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "apb_seq_item.sv"
`include "apb_slave_driver.sv"
`include "apb_monitor.sv"

class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    // Reactive Slave sub-components
    apb_slave_driver drv;
    apb_monitor      mon;

    // TLM Analysis Port forwarded from monitor
    uvm_analysis_port #(apb_seq_item) ap;

    function new(input string name = "apb_agent", input uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(input uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);

        mon = apb_monitor::type_id::create("mon", this);

        if (get_is_active() == UVM_ACTIVE) begin
            drv = apb_slave_driver::type_id::create("drv", this);
        end
    endfunction

    virtual function void connect_phase(input uvm_phase phase);
        super.connect_phase(phase);
        mon.mon_ap.connect(this.ap);
    endfunction

endclass

`endif