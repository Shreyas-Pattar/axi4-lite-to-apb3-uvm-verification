`ifndef AXI_LITE_SEQ_ITEM_SV
`define AXI_LITE_SEQ_ITEM_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

typedef enum bit {
    AXI_READ  = 1'b0,
    AXI_WRITE = 1'b1
} axi_op_e;

class axi_lite_seq_item extends uvm_sequence_item;

    // Stimulus Fields
    rand axi_op_e                  op;
    rand bit [31:0]                addr;
    rand bit [31:0]                data;
    rand bit [3:0]                 strb;
    rand int unsigned              addr_delay;
    rand int unsigned              data_delay;

    // Response Fields
    bit [1:0]                      resp;
    bit [31:0]                     rdata;

    constraint c_word_aligned {
        addr[1:0] == 2'b00;
    }

    constraint c_delays {
        addr_delay inside {[0:5]};
        data_delay inside {[0:5]};
    }

    constraint c_full_strb {
        strb == 4'b1111;
    }

    `uvm_object_utils(axi_lite_seq_item)

    function new(input string name = "axi_lite_seq_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("OP=%s ADDR=0x%08h DATA=0x%08h RESP=%b RDATA=0x%08h",
                         op.name(), addr, data, resp, rdata);
    endfunction

endclass

`endif