class memory_test extends uvm_test;

    `uvm_component_utils(memory_test)

    memory_env env;

    function new(string name = "memory_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = memory_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        memory_sequence seq;

        // Tells UVM that I am still doing work and not to end the simulation yet... 
        phase.raise_objection(this);

        // Create the sequence (recipe)
        // We do NOT pass "this" here because sequence is an object NOT a component and it does not live in the UVM hierarchy
        seq = memory_sequence::type_id::create("seq");

        // Start sequence WITH the sequencer
        seq.start(env.agent.sequencer);

        #10;

        // End run phase when everyone else is done
        phase.drop_objection(this);
    endtask

endclass