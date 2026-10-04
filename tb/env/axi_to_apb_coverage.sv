`ifndef AXI_TO_APB_COVERAGE_SV
`define AXI_TO_APB_COVERAGE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "axi_lite_seq_item.sv"

class axi_to_apb_coverage extends uvm_subscriber #(axi_lite_seq_item);
    `uvm_component_utils(axi_to_apb_coverage)

    axi_lite_seq_item cov_item;

    covergroup cg_axi_to_apb;
        // Operation Type Coverage
        cp_op: coverpoint cov_item.op {
            bins write_op = {AXI_WRITE};
            bins read_op  = {AXI_READ};
        }

        // Response Type Coverage
        cp_resp: coverpoint cov_item.resp {
            bins okay_resp   = {2'b00};
            bins slverr_resp = {2'b10};
        }

        // Address Space Segmentation
        cp_addr: coverpoint cov_item.addr {
            bins lower_zone = {[32'h0000_0000 : 32'h0000_0FFF]};
            bins mid_zone   = {[32'h0000_1000 : 32'h0000_FFFF]};
            bins upper_zone = {[32'h0001_0000 : 32'hFFFF_FFFC]};
        }

        // Cross-Coverage: Operation vs Response
        cross_op_resp: cross cp_op, cp_resp;
    endgroup

    function new(input string name = "axi_to_apb_coverage", input uvm_component parent = null);
        super.new(name, parent);
        cg_axi_to_apb = new();
    endfunction

    virtual function void write(input axi_lite_seq_item t);
        cov_item = t;
        cg_axi_to_apb.sample();
    endfunction

endclass

`endif