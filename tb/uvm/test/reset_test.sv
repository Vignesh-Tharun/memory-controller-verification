// Verify that the DUT accepts and correctly processes transactions after reset is released.
class reset_test extends uvm_test;

    `uvm_component_utils(reset_test)

    memory_env env;

    function new(
        string name = "reset_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        env = memory_env::type_id::create("env", this);

    endfunction

    task run_phase(uvm_phase phase);

        reset_sequence seq;

        phase.raise_objection(this);

        seq = reset_sequence::type_id::create("seq");

        seq.start(env.agent.sequencer);

        #10;

        phase.drop_objection(this);

    endtask

endclass