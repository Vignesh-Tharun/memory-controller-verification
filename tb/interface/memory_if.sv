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
endinterface