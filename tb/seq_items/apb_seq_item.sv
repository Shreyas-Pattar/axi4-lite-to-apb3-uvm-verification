`ifndef APB_SEQ_ITEM_SV
`define APB_SEQ_ITEM_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class apb_seq_item extends uvm_sequence_item;

    // Bus Signals Sampled by Monitor
    bit [31:0]        paddr;
    bit               pwrite;
    bit [31:0]        pwdata;
    bit [3:0]         pstrb;
    bit [31:0]        prdata;
    bit               pslverr;

    // Reactive Slave Control Knobs (Programmed by Test/Responder)
    rand int unsigned wait_cycles;
    rand bit          inject_err;

    constraint c_wait_distribution {
        wait_cycles dist {
            0      := 50,  // 50% zero-wait transfers
            [1:3]  := 35,  // 35% short stalls
            [4:8]  := 15   // 15% extended backpressure
        };
    }

    constraint c_err_distribution {
        inject_err dist {
            1'b0 := 85,    // 85% normal OKAY
            1'b1 := 15     // 15% PSLVERR injection
        };
    }

    // Single utility registration - no field automation macro bloat
    `uvm_object_utils(apb_seq_item)

    // Explicit 'input' direction for Vivado 2026 linter
    function new(input string name = "apb_seq_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("PADDR=0x%08h PWRITE=%b PWDATA=0x%08h PRDATA=0x%08h PSLVERR=%b WAIT=%0d ERR=%b",
                         paddr, pwrite, pwdata, prdata, pslverr, wait_cycles, inject_err);
    endfunction

endclass

`endif