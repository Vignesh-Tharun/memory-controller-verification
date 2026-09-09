class boundary_test extends uvm_test;

    `uvm_component_utils(boundary_test)

    memory_env env;

    function new(
        string name = "boundary_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        env = memory_env::type_id::create("env", this);

    endfunction

    task run_phase(uvm_phase phase);

        boundary_sequence seq;

        phase.raise_objection(this);

        seq = boundary_sequence::type_id::create("seq");

        seq.start(env.agent.sequencer);

        // Drain the pipeline before ending the test.
        env.agent.driver.wait_idle();

        phase.drop_objection(this);

    endtask

endclass