`ifndef AXI_LITE_SEQ_LIB_SV
`define AXI_LITE_SEQ_LIB_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "axi_lite_seq_item.sv"

// -------------------------------------------------------------
// Sequence 1: Basic Constrained Random Read/Write Burst
// -------------------------------------------------------------
class axi_lite_random_seq extends uvm_sequence #(axi_lite_seq_item);
    `uvm_object_utils(axi_lite_random_seq)

    rand int unsigned num_trans;

    constraint c_num_trans {
        num_trans inside {[20:40]};
    }

    function new(input string name = "axi_lite_random_seq");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(), $sformatf("Starting sequence with %0d transactions", num_trans), UVM_LOW)

        repeat (num_trans) begin
            req = axi_lite_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize()) begin
                `uvm_fatal("RND_FAIL", "Failed to randomize axi_lite_seq_item")
            end
            finish_item(req);
        end

        `uvm_info(get_type_name(), "Sequence finished successfully", UVM_LOW)
    endtask

endclass

// -------------------------------------------------------------
// Sequence 2: Directed Write followed by Readback to Same Address
// -------------------------------------------------------------
class axi_lite_write_readback_seq extends uvm_sequence #(axi_lite_seq_item);
    `uvm_object_utils(axi_lite_write_readback_seq)

    rand bit [31:0] test_addr;
    rand bit [31:0] test_data;

    constraint c_aligned {
        test_addr[1:0] == 2'b00;
    }

    function new(input string name = "axi_lite_write_readback_seq");
        super.new(name);
    endfunction

    virtual task body();
        // 1. Perform Write
        req = axi_lite_seq_item::type_id::create("write_req");
        start_item(req);
        req.op         = AXI_WRITE;
        req.addr       = test_addr;
        req.data       = test_data;
        req.strb       = 4'b1111;
        req.addr_delay = 0;
        req.data_delay = 0;
        finish_item(req);

        // 2. Perform Read to same address
        req = axi_lite_seq_item::type_id::create("read_req");
        start_item(req);
        req.op         = AXI_READ;
        req.addr       = test_addr;
        req.addr_delay = 0;
        finish_item(req);
    endtask

endclass

`endif