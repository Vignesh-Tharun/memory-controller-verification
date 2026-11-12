# Negative Testing: Fault Injection

A passing regression only shows that nothing failed. These experiments show that the checkers fail when something is actually wrong.

## Method

RTL faults are controlled by compile-time macros in `rtl/memory_controller.sv`. The default build defines none of them, so the normal design is unchanged. A faulty build adds one `+define+` and writes to its own folder, so it never overwrites the normal build.

```systemverilog
`ifdef BUG_LEAK
    rdata <= pending_wdata;          // injected fault: read returns the write-data register
`else
    rdata <= memory[pending_addr];   // correct behavior
`endif
```

Build a faulty version from the project root by adding the macro and a separate output folder to the normal build command:

```bash
rm -rf obj_leak
verilator --binary --language 1800-2017 --top-module tb_top \
    --timing --build-jobs 4 --coverage --trace-vcd \
    -Wno-TIMESCALEMOD -Iuvm-core/src \
    +define+UVM_NO_DPI +define+BUG_LEAK --Mdir obj_leak \
    uvm-core/src/uvm_pkg.sv rtl/memory_controller.sv \
    coverage/memory_coverage.sv tb/tb_top.sv

./obj_leak/Vtb_top +UVM_TESTNAME=write_read_test
```

## Experiments

### 1. Testbench fault: remove the end-of-test drain

**Change:** the `wait_idle()` call was removed from `memory_test`. This is a testbench change, not an RTL change.

**Expectation:** the test ends as soon as the last request is driven, before the pipeline has finished it, so the last transactions are never checked.

**Observed:**

- The simulation ended at 205 ns, the moment the 20th and last request was driven.
- The scoreboard checked 7 of the 10 reads.
- The monitor reported: `2 transaction(s) still in flight at end of test` (a `UVM_ERROR`).
- The per-run coverage counters showed `read=9` instead of 10.
- `memory_test` was reported as FAILED by the regression.

**Conclusion:** the end-of-test headcount in the monitor catches a test that ends before its last transactions complete. Without that check, this test would have passed while silently skipping its final reads.

**Reproduce:** comment out `env.agent.driver.wait_idle();` in `memory_test`, rebuild, and run `memory_test`.

## Adding a row

Run one fault at a time, starting from a build where all four tests pass. For each experiment, record the change, the expectation, the exact error lines observed, and which checker caught it (scoreboard, assertion, or end-of-test headcount). Only record results from runs that were actually executed.
