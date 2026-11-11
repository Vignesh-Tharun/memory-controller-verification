class memory_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(memory_scoreboard)

    uvm_analysis_imp #(memory_transaction, memory_scoreboard) analysis_imp;

    logic [31:0] expected_memory [0:255];

    function new(string name = "memory_scoreboard",
                 uvm_component parent = null);
        super.new(name, parent);

        // uvm_analysis_imp holds reference to my scoreboard here through "this"
        analysis_imp = new("analysis_imp", this);

        // Initialise all 256 locations with 0 in expected memory
        for (int i = 0; i < 256; i++)
            expected_memory[i] = 0;

    endfunction

    // uvm_analysis_imp calls this write function since it holds a reference to my scoreboard class
    function void write(memory_transaction tr);
        // If it is a write transaction, print this
        if (tr.write) begin
            expected_memory[tr.addr] = tr.wdata;

            `uvm_info(
                "SCOREBOARD",
                $sformatf(
                    "Expected WRITE addr=%0d data=%h",
                    tr.addr,
                    tr.wdata
                ),
                UVM_MEDIUM // Verbosity
            )
        end

        // If it is a read transaction, print this
        else begin
            // We use === instead of == for exact 4 state comparison thus X/Z
            // should also be detected unlike == logical equality
            if (expected_memory[tr.addr] === tr.rdata) begin
                `uvm_info(
                    "SCOREBOARD",
                    $sformatf(
                        "READ PASS addr=%0d data=%h",
                        tr.addr,
                        tr.rdata
                    ),
                    UVM_MEDIUM
                )
            end

            // Note: The RTL actually puts this data in pending_wdata register 
            // so if the rtl has a bug where it reads from pending wdata 
            // instead of the actual memory for a read transaction, we get the junk 
            // "DEADBEEF" data
            else begin
                `uvm_error(
                    "SCOREBOARD",
                    $sformatf(
                        "READ FAIL addr=%0d expected=%h actual=%h",
                        tr.addr,
                        expected_memory[tr.addr],
                        tr.rdata
                    )
                )
            end
        end
    endfunction
endclass