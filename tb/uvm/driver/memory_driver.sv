// Driver is what drives the DUT's input from a transaction through a virtual interface
class memory_driver extends uvm_driver #(memory_transaction);
    `uvm_component_utils(memory_driver)

    // we use a virtual memory interface for a UVM class to talk to a static DUT
    virtual memory_if vif;

    // Constructor/initializer
    function new(string name = "memory_driver",
                uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // The driver holds a REFERENCE to actual interface, that's why it is called virtual
        if (!uvm_config_db#(virtual memory_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found")
    endfunction 

    // run_phase is the actual simulation activity
    // phase argument is the current phase
    task run_phase(uvm_phase phase);
        memory_transaction tr;

        // Wait until reset released before driving transactions
        // the DUT is held in reset from 0–10 ns, then reset is released.
        @(negedge vif.rst);

        // forever begin because we want to keep waiting for transaction and drive them whenever they arrive
        forever begin
            // Wait for next transaction from sequencer
            // seq_item_port inherited variable
            // seq_item_port is the communication between driver and sequencer to receive sequence items
            seq_item_port.get_next_item(tr);

            vif.write = tr.write;
            vif.addr = tr.addr;
            vif.wdata = tr.wdata;
            vif.valid = 1;

            // Give DUT time to see the driven signals before clock edge
            #1;

            // Wait for this transaction to be captured
            @(posedge vif.clk);

            // Keep valid asserted for this complete clock cycle then deassert after edge
            #1;

            // Don't present the request anymore
            vif.valid = 0;

            // Wait for DUT to complete the request
            @(posedge vif.clk); 

            // Tell sequencer done with this transaction
            seq_item_port.item_done();
        end
    endtask

    // Drive with a memory transaction
    // task drive(memory_transaction tr);
    //     // Put the transaction into the DUT's inputs
    //     vif.write = tr.write;
    //     vif.addr = tr.addr;
    //     vif.wdata = tr.wdata;
    //     vif.valid = 1;

    //     // Wait for this transaction to be captured
    //     @(posedge vif.clk);

    //     // Don't present the request anymore
    //     vif.valid = 0;

    //     // Wait for DUR to complete the request
    //     @(posedge vif.clk); 
    // endtask
endclass