`include "uvm_macros.svh" // include macros like uvm_object_utils

import uvm_pkg::*; // imports stuff like uvm_driver, uvm_sequencer and more
 
// Represents one memory operation
// A packet of information describing one memory operation
// Not actual signals sent to DUT (Device Under Test)
// The interface makes it happen
class memory_transaction extends uvm_sequence_item;

    rand logic write;
    rand logic [7:0] addr;
    rand logic [31:0] wdata;

    `uvm_object_utils(memory_transaction)

    function new(string name = "memory_transaction");
        super.new(name);
    endfunction

    // Constraint address so that it only ranges from 0 to 255
    constraint valid_address {
        addr inside {[0:255]};
    }

endclass