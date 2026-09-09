class memory_env extends uvm_env;
    `uvm_component_utils(memory_env)

    memory_agent agent;
    memory_scoreboard scoreboard;

    function new(string name = "memory_env",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // We do pass "this" here because agent is a component that lives in the UVM hierarchy
        agent = memory_agent::type_id::create("agent", this);
        scoreboard = memory_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        agent.monitor.analysis_port.connect(
            scoreboard.analysis_imp
        );
    endfunction

endclass