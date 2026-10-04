`ifndef AXI_TO_APB_BASE_TEST_SV
`define AXI_TO_APB_BASE_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi_to_apb_env.sv"
`include "axi_lite_seq_lib.sv"

class axi_to_apb_base_test extends uvm_test;
    `uvm_component_utils(axi_to_apb_base_test)

    axi_to_apb_env env;

    function new(input string name = "axi_to_apb_base_test", input uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(input uvm_phase phase);
        super.build_phase(phase);
        env = axi_to_apb_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(input uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        // Print the active UVM component hierarchy
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(input uvm_phase phase);
        axi_lite_random_seq         rand_seq;
        axi_lite_write_readback_seq wr_rd_seq;

        phase.raise_objection(this, "Starting AXI to APB Test");

        // 1. Run Directed Write-Readback Corner Cases
        `uvm_info("TEST", "Executing Directed Write-Readback Sequence...", UVM_LOW)
        wr_rd_seq = axi_lite_write_readback_seq::type_id::create("wr_rd_seq");
        assert(wr_rd_seq.randomize() with { test_addr == 32'h0000_1000; test_data == 32'hA5A5_1234; });
        wr_rd_seq.start(env.axi_agt.sqr);

        assert(wr_rd_seq.randomize() with { test_addr == 32'h0000_2004; test_data == 32'h5A5A_9876; });
        wr_rd_seq.start(env.axi_agt.sqr);

        // 2. Run Constrained Random Burst Sequence
        `uvm_info("TEST", "Executing Constrained Random Burst Sequence...", UVM_LOW)
        rand_seq = axi_lite_random_seq::type_id::create("rand_seq");
        assert(rand_seq.randomize() with { num_trans == 30; });
        rand_seq.start(env.axi_agt.sqr);

        #100ns;
        phase.drop_objection(this, "Completed AXI to APB Test");
    endtask

endclass

`endif