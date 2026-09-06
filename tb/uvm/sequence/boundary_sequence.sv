class boundary_sequence extends uvm_sequence #(memory_transaction);

    `uvm_object_utils(boundary_sequence)

    function new(string name = "boundary_sequence");
        super.new(name);
    endfunction

    task body();

        memory_transaction tr;

        // Write to lowest address: 0
        tr = memory_transaction::type_id::create("write_low");

        start_item(tr);

        tr.write = 1;
        tr.addr  = 8'd0;
        tr.wdata = 32'hAAAAAAAA;

        finish_item(tr);

        // Read address 0
        tr = memory_transaction::type_id::create("read_low");

        start_item(tr);

        tr.write = 0;
        tr.addr  = 8'd0;

        finish_item(tr);

        // Write to medium address: 100
        tr = memory_transaction::type_id::create("write_medium");
        start_item(tr);
        tr.write = 1;
        tr.addr = 8'd100;
        tr.wdata = 32'hDDDDDDDD;
        finish_item(tr);

        // Read from medium address: 100
        tr = memory_transaction::type_id::create("read_medium");
        start_item(tr);
        tr.write = 0;
        tr.addr = 8'd100;
        finish_item(tr);

        // Write to highest address: 255
        tr = memory_transaction::type_id::create("write_high");

        start_item(tr);

        tr.write = 1;
        tr.addr  = 8'd255;
        tr.wdata = 32'hBBBBBBBB;

        finish_item(tr);

        // Read address 255
        tr = memory_transaction::type_id::create("read_high");

        start_item(tr);

        tr.write = 0;
        tr.addr  = 8'd255;

        finish_item(tr);

    endtask

endclass