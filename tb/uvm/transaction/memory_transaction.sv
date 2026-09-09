`include "uvm_macros.svh" // include macros like uvm_object_utils

import uvm_pkg::*; // imports stuff like uvm_driver, uvm_sequencer and more
 
// Represents one memory operation that driver sends to DUT
// A packet of information describing one memory operation
// Not actual signals sent to DUT (Device Under Test)
// The interface makes it happen
class memory_transaction extends uvm_sequence_item;

    rand logic write;
    rand logic [7:0] addr;
    rand logic [31:0] wdata;
    logic [31:0] rdata; // no need rand for this since it just whatever data being read

    `uvm_object_utils(memory_transaction)
    // `uvm_object_utils_begin(memory_transaction)
    //     // Field automation so I can print, copy, compare the transactions if I want
    //     `uvm_field_int(write, UVM_ALL_ON)
    //     `uvm_field_int(addr,  UVM_ALL_ON)
    //     `uvm_field_int(wdata, UVM_ALL_ON)
    //     `uvm_field_int(rdata, UVM_ALL_ON)
    // `uvm_object_utils_end

    function new(string name = "memory_transaction");
        super.new(name);
    endfunction

    // Constraint address so that it only ranges from 0 to 255
    constraint valid_address {
        addr inside {[0:255]};
    }

endclass