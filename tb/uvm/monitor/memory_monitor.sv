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

        memory_transaction tr;

        forever begin
            @(posedge vif.clk);

            if (vif.valid) begin

                // We create the transaction and write it to the analysis port
                tr = memory_transaction::type_id::create("tr");
                tr.write = vif.write;
                tr.addr  = vif.addr;
            
                if (vif.write) begin

                    // Write data is available with the request

                    tr.wdata = vif.wdata;

                    analysis_port.write(tr);

                    `uvm_info(
                        "MONITOR",
                        $sformatf(
                            "Observed WRITE addr=%0d wdata=%h",
                            tr.addr,
                            tr.wdata
                        ),
                     UVM_MEDIUM
                    )

                end

                else begin

                    // Read result is available one clock later
                    @(posedge vif.clk);

                    // DUT uses nonblocking assignment, so wait until
                    // the NBA update to rdata has occurred.

                    #1;

                    tr.wdata = vif.rdata;
                    analysis_port.write(tr);

                    `uvm_info(
                        "MONITOR",
                        $sformatf(
                            "Observed READ addr=%0d rdata=%h",
                            tr.addr,
                            tr.wdata
                        ),  
                        UVM_MEDIUM
                    )

                end
            end
        end
    endtask
endclass