// Memory assertions are rules to follow during verification
module memory_assertions(
    input logic clk,
    input logic rst,
    input logic valid,
    input logic ready
);

// property defines a rule
property valid_implies_ready;
    // At every posedge clk, check for this rule
    // Disable assertion if rst = 1
    @(posedge clk) disable iff (rst)
    /* 
        1st clock edge: UVM Driver drives input "valid" of DUT using NBA. DUT has NOT sampled this value of "valid" at this clock edge yet.
        2nd clock edge: DUT samples input "valid" and updates pending related registers
        3rd clock edge: DUT processes pending transaction and ready is asserted
        4th clock edge: "ready" is sampled here in the preponed stage
        In conclusion, it takes 2 clock cycles (i.e. between 2nd and 4th clock edges) for ready to be asserted from the point valid was asserted at the input of the DUT.
    */
    valid |-> ##2 ready;
endproperty

// Assert property
assert property (valid_implies_ready)
    else $error("ASSERTION FAILED: valid was high 2 clock cycles ago but ready is not high at this clock edge");

//     logic valid_d1;
//     logic valid_d2;

//     always_ff @(posedge clk) begin
//         if (rst) begin
//             valid_d1 <= 0;
//             valid_d2 <= 0;
//         end
//         else begin
//             // ready becomes observable one clock after the DUT
//             // processes the pending request.
//             if (valid_d2 && !ready)
//                 $error("ASSERTION FAILED: request was not completed with ready");

//             valid_d1 <= valid;
//             valid_d2 <= valid_d1;
//         end
//     end

endmodule