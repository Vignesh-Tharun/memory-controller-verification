// A monitor is NOT merely a completion checker
// A monitor is actually an observer of the interface protocol
// Monitor here handles BOTH request and completion side
// Request side: Capture valid transactions recently issued and store in FIFO
// Completion side: Ready ready transactions completed and print it out
class memory_monitor extends uvm_monitor;
    `uvm_component_utils(memory_monitor)

    virtual memory_if vif;

    uvm_analysis_port #(memory_transaction) analysis_port;

    function new(string name = "memory_monitor",
                 uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Get the reference to the interface from config_db
        if (!uvm_config_db#(virtual memory_if)::get(
                this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        // $ means unbounded queue whose size can grow and shrink dynamically
        /*
            A FIFO queue is used here since DUT is single stage so assumption is DUT 
            completes request in issue order with no reordering.
            If it is a much more complex DUT, a later issued transaction can
            complete earlier than an earlier issue transaction. Thus, an
            associative array (hashmap) would be more suitable 
            where each transaction has an associated ID to know which 
            completed first
        */
        memory_transaction inflight_q[$]; 
        memory_transaction tr;
        
        forever begin
            // wait for clock edge
            @(vif.monitor_cb);

            // If new request showed up THIS cycle
            if (vif.monitor_cb.valid) begin
                tr = memory_transaction::type_id::create("tr");
                tr.write = vif.monitor_cb.write;
                tr.addr  = vif.monitor_cb.addr;
                if (vif.monitor_cb.write)
                    tr.wdata = vif.monitor_cb.wdata;
                inflight_q.push_back(tr);
            end

            // A request finished THIS cycle
            if (vif.monitor_cb.ready && inflight_q.size() > 0) begin
                tr = inflight_q.pop_front();
                if (!tr.write)
                    tr.rdata = vif.monitor_cb.rdata;
                analysis_port.write(tr);
            end
        end

        /* 
            OLD monitor logic where it
            knows nothing else could possibly be happening at the same time — 
            there's only ever one request in flight. It 
            hard-codes the assumption that only one thing is happening at once.
        */
        // forever begin
        //     // Wait for next clock and monitor them
        //     @(vif.monitor_cb);

        //     if (vif.monitor_cb.valid) begin

        //         // We recreate the transaction and write it to scoreboard via the analysis port
        //         tr = memory_transaction::type_id::create("tr");
        //         tr.write = vif.monitor_cb.write;
        //         tr.addr  = vif.monitor_cb.addr;
            
        //         // WRITE
        //         if (vif.monitor_cb.write) begin

        //             // Write data is available with the request
        //             tr.wdata = vif.monitor_cb.wdata;

        //             // Send to scoreboard
        //             analysis_port.write(tr);

        //             `uvm_info(
        //                 "MONITOR",
        //                 $sformatf(
        //                     "Observed WRITE addr=%0d wdata=%h",
        //                     tr.addr,
        //                     tr.wdata
        //                 ),
        //                 UVM_MEDIUM // Verbosity
        //             )

        //         end
        //         // READ
        //         else begin
        //             // WAIT until ready is 1 before reading
        //             while(!vif.monitor_cb.ready) begin
        //                 @(vif.monitor_cb);
        //             end

        //             // Get the rdata
        //             tr.rdata = vif.monitor_cb.rdata;

        //             // Send to scoreboard
        //             analysis_port.write(tr);

        //             `uvm_info(
        //                 "MONITOR",
        //                 $sformatf(
        //                     "Observed READ addr=%0d rdata=%h",
        //                     tr.addr,
        //                     tr.wdata
        //                 ),  
        //                 UVM_MEDIUM
        //             )

        //         end
        //     end
        // end
    endtask
endclass