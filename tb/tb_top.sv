// include order matters here for example, driver needs to know what memory_transaction is

`include "assertions/memory_assertions.sv"
`include "tb/interface/memory_if.sv"

`include "tb/uvm/transaction/memory_transaction.sv"

`include "tb/uvm/sequence/memory_sequence.sv"
`include "tb/uvm/sequence/write_read_sequence.sv"
`include "tb/uvm/sequence/boundary_sequence.sv"
`include "tb/uvm/sequence/reset_sequence.sv"

`include "tb/uvm/sequencer/memory_sequencer.sv"
`include "tb/uvm/driver/memory_driver.sv"
`include "tb/uvm/monitor/memory_monitor.sv"
`include "tb/uvm/scoreboard/memory_scoreboard.sv"
`include "tb/uvm/agent/memory_agent.sv"
`include "tb/uvm/env/memory_env.sv"

`include "tb/uvm/test/memory_test.sv"
`include "tb/uvm/test/write_read_test.sv"
`include "tb/uvm/test/boundary_test.sv"
`include "tb/uvm/test/reset_test.sv"

module tb_top;
    logic clk;
    // logic rst;
    // logic write;
    // logic valid; // Whether to begin processing the inputs
    // logic [7:0] addr;
    // logic [31:0] wdata;
    // logic [31:0] rdata;
    // logic ready; // finished processing

    // Actual interface instance
    memory_if intf(clk);

    // Instantiate my simple DUT
    memory_controller dut (
        .clk(intf.clk),
        .rst(intf.rst),
        .write(intf.write),
        .valid(intf.valid),
        .addr(intf.addr),
        .wdata(intf.wdata),
        .rdata(intf.rdata),
        .ready(intf.ready)
    );

    // Memory coverage
    memory_coverage coverage (
        .clk   (intf.clk),
        .write (intf.write),
        .valid (intf.valid),
        .addr  (intf.addr)
    );

    // Memory assertions
    // DOES NOT drive any inputs, just watches them
    memory_assertions assertions (
        .clk(clk),
        .rst(intf.rst),
        .valid(intf.valid),
        .ready(intf.ready)
    );

    // Generate clock
    // initial block only runs once
    initial begin
        clk = 0;

        forever begin
            #5 clk = ~clk;
        end
    end

    // Tasks
    // task write_mem(input logic [7:0] address,
    //                input logic [31:0] data);
    //     // Drive signals
    //     intf.addr = address;
    //     intf.wdata = data;
    //     intf.write = 1;
    //     intf.valid = 1;

    //     // Wait for next posedge clock
    //     @(posedge clk);

    //     // Request no longer presented
    //     intf.valid = 0;

    //     // at next clock cycle, valid is already 0 so no operation would take place
    //     // DUT processes pending write
    //     @(posedge clk);
    // endtask

    // task read_mem(input logic [7:0] address);
    //     intf.addr = address;
    //     intf.write = 0;
    //     intf.valid = 1;

    //     // DUT captures read request
    //     @(posedge clk);

    //     // Request no longer presented
    //     intf.valid = 0;

    //     // DUT processes pending read
    //     @(posedge clk);
    // endtask

    initial begin
        $dumpfile("sim/memory_controller.vcd");
        $dumpvars(0, tb_top);
    end

    initial begin
        intf.rst = 1;
        intf.write = 0;
        intf.valid = 0;
        intf.addr = 0;
        intf.wdata = 0;

        #10;

        intf.rst = 0;
    end

    // Give UVM the interface
    initial begin
        uvm_config_db#(virtual memory_if)::set(
            null,
            "*",
            "vif",
            intf
        );

        run_test();
        // run_test("memory_test");
        // run_test("write_read_test");
        // run_test("boundary_test");
        // run_test("reset_test");
    end

    // Test sequence
    // initial begin
    //     // New memory transaction
    //     memory_transaction tr;

    //     // Create new driver and pass in the virtual interface
    //     driver = new(intf);

    //     // Initial values
    //     // Signals now live inside the memory interface instead of the testbench here
    //     intf.rst = 1;
    //     intf.write = 0;
    //     intf.valid = 0;
    //     intf.addr = 0;
    //     intf.wdata = 0;

    //     // Hold reset for 1 clock period
    //     // rst check in always_ff block so wait for next posedge clock for reset to be 0
    //     #10;
    //     // Set reset low to begin
    //     intf.rst = 0;

    //     @(posedge clk);

    //     // Write address 0
    //     tr = new();
    //     tr.write = 1;
    //     tr.addr = 8'd0;
    //     tr.wdata = 32'hAAAAAAAA;
    //     driver.drive(tr);

    //     // Read address 0
    //     tr = new();
    //     tr.write = 0;
    //     tr.addr = 8'd0;
    //     driver.drive(tr);

    //     // Check result for address 0
    //     // ready must be 1 and rdata be the correct one
    //     if (intf.ready && intf.rdata == 32'hAAAAAAAA) begin
    //         $display("PASS: Address 0, data = %h", intf.rdata);
    //     end
    //     else begin
    //         $display("FAIL: Address 0, expected AAAAAAAA, got %h", intf.rdata);
    //     end

    //     // Write address 255
    //     tr = new();
    //     tr.write = 1;
    //     tr.addr = 8'd255;
    //     tr.wdata = 32'hBBBBBBBB;
    //     driver.drive(tr);

    //     // Read address 255
    //     tr = new();
    //     tr.write = 0;
    //     tr.addr = 8'd255;
    //     driver.drive(tr);

    //     // Check result for address 255
    //     // ready must be 1 and rdata be the correct one
    //     if (intf.ready && intf.rdata == 32'hBBBBBBBB) begin
    //         $display("PASS: Address 255, data = %h", intf.rdata);
    //     end
    //     else begin
    //         $display("FAIL: Address 255, expected BBBBBBBB, got %h", intf.rdata);
    //     end

    //     // End simulation 
    //     $finish;
    // end

    // initial begin
    //     memory_transaction tr;
    //     tr = new();

    //     repeat (10) begin
    //         // Issue with verilator: Instead of just if (tr.randomize()), check if it returns anything other than 0
    //         if (tr.randomize() != 0) begin
    //             // Now driver uses transaction to drive the DUT's inputs through a virtual interface
    //             driver.drive(tr);
    //             // $display(
    //             //     "RANDOM: write=%0d addr=%0d wdata=%h",
    //             //     tr.write,
    //             //     tr.addr,
    //             //     tr.wdata
    //             // );
    //         end
    //         else begin
    //             $display("Randomization failed");
    //         end
    //     end
    // end

endmodule