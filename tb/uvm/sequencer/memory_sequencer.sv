// middleman that receives transactions and sends it to driver
class memory_sequencer extends uvm_sequencer #(memory_transaction);
    // Macro registers my sequencer class with factory
    // `uvm_component_utils vs `uvm_object_utils
    // Components are stuff living in UVM hierarchy like test, env, agent, driver, sequencer
    // Objects are data objects like transaction and sequence item
    `uvm_component_utils(memory_sequencer)

    function new(string name = "memory_sequencer",
                uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass