class memory_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(memory_scoreboard)

    uvm_analysis_imp #(memory_transaction, memory_scoreboard) analysis_export;

    logic [31:0] expected_memory [0:255];

    function new(string name = "memory_scoreboard",
                 uvm_component parent = null);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
        for (int i = 0; i < 256; i++)
            expected_memory[i] = 0;

    endfunction

    function void write(memory_transaction tr);

        // WRITE
        if (tr.write) begin
            expected_memory[tr.addr] = tr.wdata;

            `uvm_info(
                "SCOREBOARD",
                $sformatf(
                    "Expected WRITE addr=%0d data=%h",
                    tr.addr,
                    tr.wdata
                ),
                UVM_MEDIUM
            )

        end

        // READ
        else begin
            if (expected_memory[tr.addr] === tr.wdata) begin
                `uvm_info(
                    "SCOREBOARD",
                    $sformatf(
                        "READ PASS addr=%0d data=%h",
                        tr.addr,
                        tr.wdata
                    ),
                    UVM_MEDIUM
                )
            end

            else begin
                `uvm_error(
                    "SCOREBOARD",
                    $sformatf(
                        "READ FAIL addr=%0d expected=%h actual=%h",
                        tr.addr,
                        expected_memory[tr.addr],
                        tr.wdata
                    )
                )
            end

        end

    endfunction
endclass