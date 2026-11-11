// Memory assertions are checks on DUT's behaviour based on its spec during verification. They're not rules per-se.
module memory_assertions(
    input logic clk,
    input logic rst,
    input logic valid,
    input logic ready
);

// FORWARD CHECK: property defines a rule
property valid_then_ready_2cyc;
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
    // Note: Without the "|->" guard, "valid ##2 ready" would check FOR EVERY CLOCK CYCLE since it is a sequence and simulation would expect valid to be true for every clock cycle
    valid |-> ##2 ready;
endproperty

// "cover property" actually checks if the scenario actually happened at least ONCE
// I do NOT want a scenario where valid never gets asserted but the assertion still passes. That is an assertion passing vacuously meaning it never happened anyway and it still passes
cover property (@(posedge clk) disable iff (rst) valid ##2 ready);

// REVERSE CHECK: ready must be asserted only when valid was asserted 2 cycles ago. 
// ready is "a result of" valid so reverse check is required to avoid scenarios of ready being asserted falsely.
// Do not want a response when there was no request in the first place.
property ready_needs_valid;
    @(posedge clk) disable iff (rst)

    // use $past function to check where valid must be asserted 2 cycles ago when ready is asserted
    ready |-> $past(valid, 2);
endproperty

// Check to ensure valid and ready are NOT X or Z
property no_highimpedance_or_unknown;
    @(posedge clk) disable iff (rst)

    // meaningful on 4-state simulators; Verilator is 2-state, so it can’t fire here.
    !$isunknown({valid, ready});
endproperty

// Assert properties
assert property (valid_then_ready_2cyc)
    else $error("ASSERTION FAILED: valid was high 2 clock cycles ago but ready is not high at this clock edge");

assert property (ready_needs_valid)
    else $error("ASSERTION FAILED: ready is high at this clock edge but valid was not high 2 clock cycles ago");

assert property (no_highimpedance_or_unknown)
    else $error("ASSERTION FAILED: X/Z on ready/valid");

endmodule