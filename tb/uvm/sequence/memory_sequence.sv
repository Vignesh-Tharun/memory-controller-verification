class memory_sequence extends uvm_sequence #(memory_transaction);
    // Registers my sequence class with factory
    `uvm_object_utils(memory_sequence)

    function new(string name = "memory_sequence");
        super.new(name);
    endfunction

    task body();
        // Store the randomized addresses so we can read them back later 
        logic [7:0] written_addresses [10];

        memory_transaction tr;

        // Write values to various addresses
        for (int i = 0; i < 10; i++) begin
            tr = memory_transaction::type_id::create("tr");
            start_item(tr);

            // Do not use assert(tr.randomize()), if not, error would be printed but the simulation would continue silently causing random bugs
            if ((tr.randomize() with {
                write == 1;
            }) == 0)    
                `uvm_fatal("RANDFAIL", "Write transaction randomization failed")

            // Remember the address that was written
            written_addresses[i] = tr.addr;
            
            finish_item(tr);
        end

        // Read the same addresses back
        for (int i = 0; i < 10; i++) begin
            tr = memory_transaction::type_id::create("read_tr");
            start_item(tr);
            if ((tr.randomize() with {
                write == 0;
                addr == written_addresses[i];
            }) == 0)    
                `uvm_fatal("RANDFAIL", "Write transaction randomization failed")
            finish_item(tr);
        end
    endtask
endclass