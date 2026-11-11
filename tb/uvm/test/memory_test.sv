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

    // 1. Sequence calls finish_item(tr) for the LAST item → blocks, waiting
    // 2. Driver's turn comes on the clock: drives it, calls item_done()
    // 3. The moment item_done() fires → finish_item() unblocks
    // 4. sequence's body() task has nothing left to do → it ends
    // 5. seq.start() (which was just waiting for body() to finish) returns
    task run_phase(uvm_phase phase);
        memory_sequence seq;

        // Tells UVM that I am still doing work and not to end the simulation yet... 
        phase.raise_objection(this);

        // Create the sequence (recipe)
        // We do NOT pass "this" here because sequence is an object NOT a component and it does not live in the UVM hierarchy
        seq = memory_sequence::type_id::create("seq");

        // Start sequence WITH the sequencer
        seq.start(env.agent.sequencer);

        // Drain the pipeline before ending the test.
        /* 
            Note: If this gets commented out, uvm error would be thrown during 
            the check phase where 2 transactions would be caught being in flight.

            First thing first, it is important to remember that the monitor samples
            in the preponed stage. Thus even if the RTL outputs at one clock edge,
            the monitor can ONLY SAMPLE AT THE NEXT CLOCK EDGE to print it out.

            Second thing, when it says a simulation ends at 205ns or 245ns or 
            whatever it is, whatever is supposed to happpen at that clock edge gets
            executed before objection is dropped and the simulation ends.

            Without this wait_idle function call, 4 clock cycles is eliminated thus
            simulation ends at 205ns instead of 245ns.

            With this wait_idle() function, simulation ends at 245ns where 235-245ns 
            is the extra margin of clock cycle. So 8th read transaction gets 
            printed by scoreboard (passed to scoreboard by monitor AT THE SAME CLOCK EDGE)
            at 215ns, 9th at 225ns, 10th at 235ns... Again, take note, the RTL drove
            the outputs 1 clock period before it so the transactions gets processed and
            the outputs appeared at 205ns, 215ns, 225ns respectively for the 8th to 10th 
            read transactions. 
            
            So I can determine that the 8th transaction entered the queue at 195ns, 
            9th at 205ns and 10th at 215ns. Thus when simulation ended at 205ns, 
            8th and 9th were stuck in the queue and 10th has still yet to enter the 
            queue and thus check phase of monitor prints out 2 transactions still
            in mid-flight.

            Critical note: The DUT processes read 8 at 205, but the monitor can’t see 
            that completion until 215, so it stays in the queue until then. “Evicted”
            off the inflight queue means the monitor saw it complete, and that’s one 
            edge after the DUT did so that's why the read 8 was stuck in the queue
            on the monitor side.

            So the 8th read transaction never gets printed out since it only gets
            sampled by monitor at 215ns even though the RTL drove the outputs at 205ns
            when the objection gets dropped and the simulation ended.
        */
        env.agent.driver.wait_idle();

        // End run phase when everyone else is done
        phase.drop_objection(this);
    endtask

endclass