// Interface is like a bundle of wires that connect testbench to DUT\
// Usually clk is provided externally to avoid coupling
interface memory_if(input logic clk);
    logic rst;
    logic write;
    logic valid;

    logic [7:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic ready;

    // Eliminates race conditions between DUT and testbench
    // A clocking block controls when the testbench drives DUT inputs 
    // and when the testbench samples DUT outputs, 
    // relative to the clock edge.
    clocking driver_cb @(posedge clk);
        // 1 step is the smallest simulation time precision
        // input 1step before clock edge
        // output 1step after clock edge
        default input #1step output #0;

        output write;
        output valid;
        output addr;
        output wdata;
        input rdata;
        input ready;
    endclocking

    clocking monitor_cb @(posedge clk);
        // 1 step is the smallest simulation time precision
        // input 1step before clock edge
        // output 1step after clock edge
        default input #1step;

        input write;
        input valid;
        input addr;
        input wdata;
        input rdata;
        input ready;
    endclocking

endinterface