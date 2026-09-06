class write_read_sequence extends uvm_sequence #(memory_transaction);

    `uvm_object_utils(write_read_sequence)

    function new(string name = "write_read_sequence");
        super.new(name);
    endfunction

    task body();

        memory_transaction tr;

        // Directed write
        tr = memory_transaction::type_id::create("write_tr");

        start_item(tr);

        tr.write = 1;
        tr.addr  = 8'd10;
        tr.wdata = 32'hAAAAAAAA;

        finish_item(tr);

        // Directed read of the same address
        tr = memory_transaction::type_id::create("read_tr");

        start_item(tr);

        tr.write = 0;
        tr.addr  = 8'd10;

        finish_item(tr);

    endtask

endclass