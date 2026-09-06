// Memory assertions are rules to follow during verification

module memory_assertions(
    input logic clk,
    input logic rst,
    input logic valid,
    input logic ready
);

    logic valid_d1;
    logic valid_d2;

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_d1 <= 0;
            valid_d2 <= 0;
        end
        else begin
            // ready becomes observable one clock after the DUT
            // processes the pending request.
            if (valid_d2 && !ready)
                $error("ASSERTION FAILED: request was not completed with ready");

            valid_d1 <= valid;
            valid_d2 <= valid_d1;
        end
    end

endmodule

// module memory_assertions(
//     input logic clk,
//     input logic rst,
//     input logic valid,
//     input logic ready
// );

// // property defines a rule
// property valid_implies_ready;
//     // At every posedge clk, check for this rule
//     // Disable assertion if rst = 1
//     @(posedge clk) disable iff (rst)
//     // ##1 wait for one clock later to check if ready is 1. 
//     // Ready = 1 doesnt happen instantly at posedge so wait for next clock posedge
//     // Since we used NBA in DUT, ready value not visible immediately for same clock edge evaluation
//     valid |-> ##1 ready;
// endproperty

// // Assert property
// assert property (valid_implies_ready)
//     else $error("ASSERTION FAILED: valid was high but ready was not high at the next clock");

// endmodule