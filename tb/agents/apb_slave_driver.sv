`ifndef APB_SLAVE_DRIVER_SV
`define APB_SLAVE_DRIVER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "apb_seq_item.sv"

class apb_slave_driver extends uvm_driver #(apb_seq_item);
    `uvm_component_utils(apb_slave_driver)

    virtual apb_if vif;

    // Internal Memory Model to service reads
    bit [31:0] mem[bit [31:0]];

    // Default responder configuration
    int unsigned default_wait_cycles = 0;
    bit          default_inject_err  = 0;

    function new(input string name = "apb_slave_driver", input uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(input uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("SLV_NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    virtual task run_phase(input uvm_phase phase);
        reset_signals();
        wait (vif.aresetn === 1'b1);

        forever begin
            respond_to_transfer();
        end
    endtask

    virtual task reset_signals();
        wait (vif.aresetn === 1'b0);
        vif.slv_cb.pready  <= 1'b1; // Default to ready
        vif.slv_cb.prdata  <= '0;
        vif.slv_cb.pslverr <= 1'b0;
    endtask

    virtual task respond_to_transfer();
        apb_seq_item resp_item;
        int unsigned wait_cnt;
        bit inject_e;

        // Sample optionally from sequencer if provided, otherwise randomize knobs
        resp_item = apb_seq_item::type_id::create("resp_item");
        if (!resp_item.randomize()) begin
            wait_cnt = default_wait_cycles;
            inject_e = default_inject_err;
        end else begin
            wait_cnt = resp_item.wait_cycles;
            inject_e = resp_item.inject_err;
        end

        // Wait for Setup Phase (PSEL asserted, PENABLE deasserted)
        do @(vif.slv_cb); while (!(vif.slv_cb.psel && !vif.slv_cb.penable));

        // Enter Access Phase
        if (wait_cnt > 0) begin
            vif.slv_cb.pready <= 1'b0;
            repeat (wait_cnt) @(vif.slv_cb);
        end

        // Conclude Transfer
        vif.slv_cb.pready  <= 1'b1;
        vif.slv_cb.pslverr <= inject_e;

        if (!vif.slv_cb.pwrite) begin
            vif.slv_cb.prdata <= mem.exists(vif.slv_cb.paddr) ? mem[vif.slv_cb.paddr] : 32'hDEADBEEF;
        end else begin
            if (!inject_e) begin
                mem[vif.slv_cb.paddr] = vif.slv_cb.pwdata;
            end
        end

        // Step past completion
        @(vif.slv_cb);
        vif.slv_cb.pslverr <= 1'b0;
    endtask

endclass

`endif