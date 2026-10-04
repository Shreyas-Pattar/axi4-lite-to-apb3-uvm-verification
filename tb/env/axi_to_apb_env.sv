`ifndef AXI_TO_APB_ENV_SV
`define AXI_TO_APB_ENV_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi_lite_agent.sv"
`include "apb_agent.sv"
`include "axi_to_apb_scoreboard.sv"
`include "axi_to_apb_coverage.sv"

class axi_to_apb_env extends uvm_env;
    `uvm_component_utils(axi_to_apb_env)

    axi_lite_agent        axi_agt;
    apb_agent             apb_agt;
    axi_to_apb_scoreboard scb;
    axi_to_apb_coverage   cov;

    function new(input string name = "axi_to_apb_env", input uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(input uvm_phase phase);
        super.build_phase(phase);

        uvm_config_db#(uvm_active_passive_enum)::set(this, "axi_agt", "is_active", UVM_ACTIVE);
        axi_agt = axi_lite_agent::type_id::create("axi_agt", this);

        uvm_config_db#(uvm_active_passive_enum)::set(this, "apb_agt", "is_active", UVM_ACTIVE);
        apb_agt = apb_agent::type_id::create("apb_agt", this);

        scb = axi_to_apb_scoreboard::type_id::create("scb", this);
        cov = axi_to_apb_coverage::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(input uvm_phase phase);
        super.connect_phase(phase);

        // Connect agent analysis ports to scoreboard
        axi_agt.ap.connect(scb.axi_export);
        apb_agt.ap.connect(scb.apb_export);

        // Connect AXI analysis port to functional coverage subscriber
        axi_agt.ap.connect(cov.analysis_export);
    endfunction

endclass

`endif