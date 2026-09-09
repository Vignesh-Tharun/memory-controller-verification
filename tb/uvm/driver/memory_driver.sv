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
        // the DUT is held in reset from 0–10 ns, then reset is released at 10ns.
        @(negedge vif.rst);

        // forever begin because we want to keep waiting for transaction and drive them whenever they arrive
        forever begin
            // NEW driver logic: send a request EVERY clock cycle
            @(vif.driver_cb);

            seq_item_port.try_next_item(tr);

            if (tr != null) begin
                // Drive it and immediately mark it done
                // Monitor's and scoreboard's problem to see for completion
                vif.driver_cb.write <= tr.write;
                vif.driver_cb.addr  <= tr.addr;
                vif.driver_cb.wdata <= tr.wdata;
                vif.driver_cb.valid <= 1;
                seq_item_port.item_done();
            end
            else begin
                // If nothing is ready, drive an empty cycle
                vif.driver_cb.valid <= 0;
            end

            // OLD driver logic: sends a request and always wait for 3 cycles

            // // Wait for next transaction from sequencer
            // // seq_item_port inherited variable
            // // seq_item_port is the communication between driver and sequencer to receive sequence items
            // seq_item_port.get_next_item(tr);

            // // Wait for a posedge clk
            // @(vif.driver_cb);

            // vif.driver_cb.write <= tr.write;
            // vif.driver_cb.addr <= tr.addr;
            // vif.driver_cb.wdata <= tr.wdata;
            // vif.driver_cb.valid <= 1;

            // // Wait for the next posedge clk
            // // The request has now been presented for the DUT to sample.
            // @(vif.driver_cb);

            // // Don't present the request anymore
            // vif.driver_cb.valid <= 0;

            // // Wait for DUT to complete the request
            // @(vif.driver_cb); 

            // // Tell sequencer done with this transaction
            // seq_item_port.item_done();
        end
    endtask

    // Drain the pipeline before ending the test.
    // seq.start() returns the cycle item_done() fires for the LAST item —
    // that's when the driver PRESENTS it, not when the DUT actually finishes it.
    // Chain: 1 cycle for the DUT to even see that valid (clocking block
    // drive delay) + 2 cycles for the DUT to complete it which means 3 cycles minimum.
    // Using 4 for one additional cycle of margin.
    task wait_idle(int cycles = 4);
        repeat (cycles) @(vif.driver_cb);
    endtask
endclass