class write_read_test extends uvm_test;

    `uvm_component_utils(write_read_test)

    memory_env env;

    function new(
        string name = "write_read_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        env = memory_env::type_id::create("env", this);

    endfunction

    task run_phase(uvm_phase phase);

        write_read_sequence seq;

        phase.raise_objection(this);

        seq = write_read_sequence::type_id::create("seq");

        seq.start(env.agent.sequencer);

        #10;

        phase.drop_objection(this);

    endtask

endclass