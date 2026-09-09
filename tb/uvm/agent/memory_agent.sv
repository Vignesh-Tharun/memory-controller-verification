class memory_agent extends uvm_agent;
    `uvm_component_utils(memory_agent)

    memory_sequencer sequencer;
    memory_driver driver;
    memory_monitor monitor;

    function new(string name = "memory_agent",
                uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        sequencer = memory_sequencer::type_id::create("sequencer", this);
        driver = memory_driver::type_id::create("driver", this);
        monitor = memory_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // connect driver's sequence item port to sequencer's sequence item export
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass
