// ` are compiler directives
`timescale 1ns/1ps

module memory_controller(
    // logic has 4 states: 0, 1, Z, X (unknown)
    input logic clk,
    input logic rst,

    // write determines if read or write operation
    input logic write,

    // valid determines if an operation is happening in the first place
    // meaning the input signals are ready to be processed
    input logic valid,

    input logic [7:0] addr,
    input logic [31:0] wdata,

    output logic [31:0] rdata,

    // Once request is complete, ready goes 1
    output logic ready
);

// 32 bit words and 256 of them
logic [31:0] memory [0:255];

/* 
IMPT Note: Added pending related variables to make DUT behave like a realistic
synchronous interface. It stores incoming request and takes one clock cycle
to complete each request to model one cycle latency. Thus, need to remember
the request between those 2 clock cycles
*/
// Pending request information (No need for pending rdata because it is not needed to be stored for future use)
logic pending; // Work carried over from previous clock cycle
logic pending_write;
logic [7:0] pending_addr;
logic [31:0] pending_wdata;

// Sequential logic
// <= non blockin operation for sequential logic occurring together at the clock edge.
always_ff @(posedge clk) begin 

    if (rst) begin
        // we reset what the memory controller is responsible for
        // reset its own outputs
        ready <= 0;
        rdata <= 0;

        pending <= 0;
        pending_write <= 0;
        pending_addr <= 0;
        pending_wdata <= 0;
    end

    else begin
        ready <= 0;

        // input are ready to be processed
        // Process previous request
        if (pending) begin
            if (pending_write) begin
                memory[pending_addr] <= pending_wdata;
            end
            
            else begin
                rdata <= memory[pending_addr];
            end

            // Request complete
            ready <= 1;
        end

        // IMPT: Capture new current request
        // CYCLE 1: Request A
        // CYCLE 2: Request B, Request A complete
        // CYCLE 3: Request C, Request B complete
        pending <= valid;

        if (valid) begin
            pending_write <= write;
            pending_addr <= addr;
            pending_wdata <= wdata;
        end
    end
end

endmodule