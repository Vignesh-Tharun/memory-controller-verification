module memory_coverage (
    input logic clk,
    input logic write,
    input logic valid,
    input logic [7:0] addr
);

// List of stuff to keep track of
// Coverage group samples only for valid transactions
// I don't want cycles where valid = 0 and garbage write/addr values
// be counted in my coverage bins
covergroup memory_cg @(posedge clk iff valid);

    // Keep track of a particular signal and what values it take
    // operation is the NAME given to coverpoint
    operation: coverpoint write {
        // We create bins to check if we have hit both buckets/ covered both operations during testing
        // bins define specific ranges I want to track for functional coverage
        bins READ = {0};
        bins WRITE = {1};
    }

    address: coverpoint addr {
        bins LOW = {[0:63]};
        bins MEDIUM = {[64:191]};
        bins HIGH = {[192:255]};
    }

endgroup

// Create instance of covergroup
memory_cg cg = new();

endmodule