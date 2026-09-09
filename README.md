# Memory Controller Verification with SystemVerilog and UVM

## Overview

This project implements a SystemVerilog/UVM-based verification environment for a simplified synchronous memory controller.

The project was built as a self-directed effort to develop verification concepts relevant to digital IP and DDR/PHY verification environments, including:

- UVM testbench architecture
- Directed and constrained-random testing
- Functional coverage
- Assertions
- Scoreboard-based checking
- Regression automation
- Simulation debugging and waveform analysis

The DUT is intentionally implemented as a simplified, single-stage pipelined memory controller with **one-cycle request latency** rather than a full DDR PHY. The design supports **back-to-back request acceptance on consecutive clock cycles**. The focus of the project is on demonstrating a structured verification methodology, reusable UVM verification components, functional coverage, assertions, and transaction-level checking.

## DUT

The memory controller provides a simple synchronous request interface supporting:

- Read operations
- Write operations
- 8-bit addresses
- 32-bit data
- 256 memory locations
- One-cycle request processing latency
- `valid` / `ready` handshaking

A request is captured when `valid` is asserted and processed on the following clock cycle.

## Verification Architecture

The testbench uses a standard UVM architecture:

```text
                    +----------------+
                    |   UVM Test     |
                    +-------+--------+
                            |
                            v
                    +----------------+
                    |    Sequence    |
                    +-------+--------+
                            |
                            v
                    +----------------+
                    |   Sequencer    |
                    +-------+--------+
                            |
                            v
                    +----------------+
                    |    Driver      |
                    +-------+--------+
                            |
                            v
                    +----------------+
                    |      DUT       |
                    | Memory Ctrl    |
                    +-------+--------+
                            |
                            v
                    +----------------+
                    |    Monitor     |
                    +-------+--------+
                            |
                            v
                    +----------------+
                    |   Scoreboard   |
                    +----------------+
```

The monitor observes transactions from the DUT interface and forwards them to the scoreboard through a UVM analysis port.

The scoreboard maintains a reference model of the expected memory contents and compares observed read data against the expected values.

## UVM Components

| Component | Purpose |
|---|---|
| Transaction | Represents memory read/write operations |
| Sequence | Generates constrained-random traffic |
| Sequencer | Supplies transactions to the driver |
| Driver | Converts transactions into DUT interface signals |
| Monitor | Observes DUT activity |
| Scoreboard | Checks read data against the reference model |
| Agent | Encapsulates sequencer, driver and monitor |
| Environment | Connects the verification components |
| Tests | Select different verification scenarios |

## Verification Tests

Four test scenarios are included.

### 1. Constrained-Random Test

Generates randomized write transactions followed by reads from the same addresses.

This verifies normal read/write functionality across a range of addresses and data values.

### 2. Directed Write/Read Test

Performs a deterministic write followed by a read:

```text
Address: 10
Data:    0xAAAAAAAA
```

The readback value is checked by the scoreboard.

### 3. Boundary Test

Explicitly exercises the lowest, middle and highest address regions:

```text
Address 0    → LOW
Address 100  → MEDIUM
Address 255  → HIGH
```

This ensures the functional coverage address bins are exercised.

### 4. Reset Recovery Test

Verifies that normal memory transactions can be performed after the initial reset sequence.

This test focuses on post-reset functionality rather than comprehensive reset behavior.

## Functional Coverage

The verification environment includes functional coverage for:

### Operation

- READ
- WRITE

### Address

- LOW: 0–63
- MEDIUM: 64–191
- HIGH: 192–255

The final coverage run achieved:

**100% functional coverage (5/5 bins)**

```text
covergroup : 100.0% (5/5)
```

The coverage model is intentionally focused on meaningful verification scenarios rather than attempting to maximize simulator-generated code coverage from the entire UVM framework.

## Assertions

A SystemVerilog assertion module monitors the relationship between request activity and completion.

The assertion checks that a captured request eventually results in the expected `ready` response according to the DUT's registered timing behavior.

This provides an additional protocol-level check alongside the scoreboard.

## Regression

A Python regression script automatically runs all four UVM tests:

```text
memory_test
write_read_test
boundary_test
reset_test
```

The regression checks the simulator output for UVM errors and fatal errors and reports the overall result.

Final regression result:

```text
All 4 tests PASSED.
```

Each test completed with:

```text
UVM_ERROR : 0
UVM_FATAL : 0
```

## Tools

- SystemVerilog
- UVM
- Verilator 5.052
- Python
- Git / GitHub

## Project Structure

```text
memory-controller-verification/
├── rtl/
│   └── memory_controller.sv
├── tb/
│   ├── interface/
│   │   └── memory_if.sv
│   ├── uvm/
│   │   ├── transaction/
│   │   ├── sequence/
│   │   ├── sequencer/
│   │   ├── driver/
│   │   ├── monitor/
│   │   ├── agent/
│   │   ├── scoreboard/
│   │   ├── env/
│   │   ├── test/
│   │   └── scripts/
│   │       └── regression.py
│   └── tb_top.sv
├── assertions/
│   └── memory_assertions.sv
├── coverage/
│   └── memory_coverage.sv
├── sim/
├── docs/
│   ├── architecture.md
│   └── waveform_pipelined_memory_test.png
├── README.md
└── .gitignore
```

## Key Verification Concepts Demonstrated

This project demonstrates practical experience with:

- UVM component hierarchy and phases
- Sequence-driven stimulus generation
- Constrained-random verification
- Directed testing
- Transaction-level modeling
- Virtual interfaces
- Scoreboard/reference-model checking
- Functional coverage
- SystemVerilog assertions
- Regression automation
- Simulation failure analysis

The verification environment is designed to reflect the structured methodology used when verifying larger digital IP blocks, while keeping the DUT small enough to understand and debug independently.
