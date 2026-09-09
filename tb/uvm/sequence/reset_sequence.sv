class reset_sequence extends uvm_sequence #(memory_transaction);

    `uvm_object_utils(reset_sequence)

    function new(string name = "reset_sequence");
        super.new(name);
    endfunction

    task body();

        memory_transaction tr;

        // Perform a transaction after reset
        tr = memory_transaction::type_id::create("post_reset_write");

        start_item(tr);

        tr.write = 1;
        tr.addr  = 8'd5;
        tr.wdata = 32'hCCCCCCCC;

        finish_item(tr);

        // Read back to verify the DUT works after reset
        tr = memory_transaction::type_id::create("post_reset_read");

        start_item(tr);

        tr.write = 0;
        tr.addr  = 8'd5;

        finish_item(tr);

    endtask

endclass