`ifndef AXI_TO_APB_SCOREBOARD_SV
`define AXI_TO_APB_SCOREBOARD_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi_lite_seq_item.sv"
`include "apb_seq_item.sv"

`uvm_analysis_imp_decl(_axi)
`uvm_analysis_imp_decl(_apb)

class axi_to_apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_to_apb_scoreboard)

    uvm_analysis_imp_axi #(axi_lite_seq_item, axi_to_apb_scoreboard) axi_export;
    uvm_analysis_imp_apb #(apb_seq_item,      axi_to_apb_scoreboard) apb_export;

    axi_lite_seq_item axi_q[$];
    apb_seq_item      apb_q[$];

    int unsigned match_count = 0;
    int unsigned error_count = 0;

    function new(input string name = "axi_to_apb_scoreboard", input uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(input uvm_phase phase);
        super.build_phase(phase);
        axi_export = new("axi_export", this);
        apb_export = new("apb_export", this);
    endfunction

    virtual function void write_axi(input axi_lite_seq_item item);
        axi_q.push_back(item);
        compare_trans();
    endfunction

    virtual function void write_apb(input apb_seq_item item);
        apb_q.push_back(item);
        compare_trans();
    endfunction

    virtual function void compare_trans();
        while (axi_q.size() > 0 && apb_q.size() > 0) begin
            axi_lite_seq_item axi = axi_q.pop_front();
            apb_seq_item      apb = apb_q.pop_front();

            // 1. Verify Direction
            if ((axi.op == AXI_WRITE && !apb.pwrite) || (axi.op == AXI_READ && apb.pwrite)) begin
                `uvm_error("SCB_DIR_MISMATCH", $sformatf("Direction mismatch: AXI op=%s vs APB pwrite=%b", 
                           axi.op.name(), apb.pwrite));
                error_count++;
                continue;
            end

            // 2. Verify Address
            if (axi.addr !== apb.paddr) begin
                `uvm_error("SCB_ADDR_MISMATCH", $sformatf("Address mismatch: AXI=0x%08h APB=0x%08h", 
                           axi.addr, apb.paddr));
                error_count++;
            end

            // 3. Verify Write Data
            if (axi.op == AXI_WRITE) begin
                if (axi.data !== apb.pwdata) begin
                    `uvm_error("SCB_WDATA_MISMATCH", $sformatf("Write data mismatch: AXI=0x%08h APB=0x%08h", 
                               axi.data, apb.pwdata));
                    error_count++;
                end else begin
                    match_count++;
                    `uvm_info("SCB_MATCH", $sformatf("WRITE PASS: Addr=0x%08h Data=0x%08h", axi.addr, axi.data), UVM_HIGH);
                end
            end
            // 4. Verify Read Data
            else begin
                if (!apb.pslverr && (axi.rdata !== apb.prdata)) begin
                    `uvm_error("SCB_RDATA_MISMATCH", $sformatf("Read data mismatch: AXI=0x%08h APB=0x%08h", 
                               axi.rdata, apb.prdata));
                    error_count++;
                end else begin
                    match_count++;
                    `uvm_info("SCB_MATCH", $sformatf("READ PASS: Addr=0x%08h RData=0x%08h", axi.addr, axi.rdata), UVM_HIGH);
                end
            end

            // 5. Verify Protocol Error Mapping (PSLVERR -> SLVERR 2'b10)
            if (apb.pslverr && (axi.resp !== 2'b10)) begin
                `uvm_error("SCB_RESP_ERR", $sformatf("APB PSLVERR was 1, but AXI RESP was 2'b%02b (expected 2'b10)", axi.resp));
                error_count++;
            end
        end
    endfunction

    virtual function void report_phase(input uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB_REPORT", "==================================================", UVM_LOW)
        `uvm_info("SCB_REPORT", $sformatf(" TOTAL TRANSACTIONS VERIFIED : %0d", match_count), UVM_LOW)
        `uvm_info("SCB_REPORT", $sformatf(" TOTAL VERIFICATION FAILURES : %0d", error_count), UVM_LOW)
        `uvm_info("SCB_REPORT", "==================================================", UVM_LOW)

        if (error_count == 0 && match_count > 0) begin
            `uvm_info("FINAL_STATUS", "***********************************", UVM_LOW)
            `uvm_info("FINAL_STATUS", "*** UVM TESTBENCH PASSED CLEANLY ***", UVM_LOW)
            `uvm_info("FINAL_STATUS", "***********************************", UVM_LOW)
        end else begin
            `uvm_fatal("FINAL_STATUS", "!!! UVM TESTBENCH FAILED WITH MISMATCHES !!!")
        end
    endfunction

endclass

`endif