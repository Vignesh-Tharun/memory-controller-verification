# Verification Architecture

## 1. Overview

This project verifies a simplified synchronous memory controller using SystemVerilog and UVM.

The verification environment separates stimulus generation, DUT driving, observation, checking, coverage, and protocol assertions into dedicated components.

The overall flow is:

```text
Test
  |
  v
Sequence
  |
  v
Sequencer
  |
  v
Driver -----> DUT
                |
                v
             Monitor
                |
                v
           Scoreboard
```

Functional coverage and assertions operate alongside the UVM environment.

---

## 2. DUT Architecture

The DUT is a simplified synchronous memory controller containing:

- 256 memory locations
- 8-bit address
- 32-bit write/read data
- `valid` request signal
- `ready` completion signal
- Read and write operation selection through `write`
- One-cycle request processing latency

The controller captures an incoming request and processes the previously captured request on the next clock edge.

### Request Flow

```text
Cycle N:
    valid = 1
    write/address/data are captured

Cycle N+1:
    Previously captured request is processed
    ready = 1
    Read data is updated for read requests
```

This timing behavior is important to the verification environment because the monitor must observe read data after the DUT has updated it.

---

## 3. UVM Environment

### Transaction

`memory_transaction` represents a single memory operation.

It contains:

- `write`
- `addr`
- `wdata`

The address field is constrained to the valid 8-bit memory address range.

---

### Sequence

Sequences generate transactions and define verification scenarios.

The environment contains:

- `memory_sequence`
- `write_read_sequence`
- `boundary_sequence`
- `reset_sequence`

The main sequence generates constrained-random write/read traffic, while the other sequences provide deterministic scenarios targeting specific behaviors.

---

### Sequencer

The sequencer controls the flow of transactions from the sequence to the driver.

```text
Sequence
   |
   v
Sequencer
   |
   v
Driver
```

---

### Driver

The driver converts UVM transactions into pin-level DUT activity through a virtual interface.

For each transaction, it drives:

- `valid`
- `write`
- `addr`
- `wdata`

The driver also accounts for the DUT's synchronous request timing.

---

### Monitor

The monitor passively observes the DUT interface.

It reconstructs transactions from the observed signals and sends them through a UVM analysis port.

```text
DUT
 |
 v
Monitor
 |
 v
Analysis Port
```

For read transactions, the monitor waits for the appropriate clock edge before sampling the returned data.

---

### Scoreboard

The scoreboard maintains a reference model of the expected memory contents.

For writes:

```text
expected_memory[address] = write_data
```

For reads:

```text
expected_data = expected_memory[address]
actual_data   = DUT read data
```

The scoreboard reports an error whenever the expected and observed values differ.

This provides self-checking verification rather than relying only on visual inspection of simulation output.

---

## 4. Test Scenarios

### Constrained-Random Test

The random sequence performs multiple writes to randomized addresses followed by reads from those addresses.

This provides broader stimulus than a single directed transaction.

### Directed Write/Read Test

A known value is written to a known address and then read back.

This provides a simple deterministic sanity check.

### Boundary Test

The test explicitly exercises:

- Address `0`
- Address `100`
- Address `255`

These addresses cover the LOW, MEDIUM and HIGH functional coverage regions.

### Reset Recovery Test

The test performs a write/read transaction after the initial reset sequence.

This verifies that the controller can resume normal functionality after reset.

---

## 5. Functional Coverage

The functional coverage model contains two coverpoints.

### Operation Coverage

```text
READ
WRITE
```

### Address Coverage

```text
LOW      : 0–63
MEDIUM   : 64–191
HIGH     : 192–255
```

The final coverage run achieved:

```text
covergroup : 100.0% (5/5)
```

All five intended functional coverage bins were exercised.

---

## 6. Assertions

A dedicated assertion module monitors request/completion timing.

The assertion uses delayed versions of `valid` to account for the DUT's registered behavior and checks that a request results in the expected `ready` response.

This provides a protocol-oriented check independent of the scoreboard's data comparison.

The assertion was verified across the complete test suite without assertion failures.

---

## 7. Regression Automation

The project includes a Python regression script located at:

```text
tb/uvm/scripts/regression.py
```

The script executes:

```text
memory_test
write_read_test
boundary_test
reset_test
```

For each test, the script checks the UVM report for:

```text
UVM_ERROR : 0
UVM_FATAL : 0
```

The final regression result was:

```text
All 4 tests PASSED.
```

This provides a repeatable way to execute the verification suite rather than manually launching each test.

---

## 8. Verification Results

| Area | Result |
|---|---|
| Random test | PASS |
| Directed write/read | PASS |
| Boundary test | PASS |
| Reset recovery | PASS |
| UVM errors | 0 |
| UVM fatals | 0 |
| Functional coverage | 100% (5/5) |
| Assertion failures | 0 |

---

## 9. Verification Methodology

The environment follows a layered verification approach:

```text
                +----------------------+
                |       Tests          |
                +----------+-----------+
                           |
                +----------v-----------+
                |      Sequences       |
                +----------+-----------+
                           |
                +----------v-----------+
                |      Sequencer       |
                +----------+-----------+
                           |
                +----------v-----------+
                |       Driver         |
                +----------+-----------+
                           |
                           v
                     +-----------+
                     |    DUT    |
                     +-----+-----+
                           |
                +----------v-----------+
                |       Monitor        |
                +----------+-----------+
                           |
                +----------v-----------+
                |      Scoreboard      |
                +----------------------+

        Coverage and assertions operate
        alongside the verification flow.
```

This structure allows stimulus generation, observation, checking and coverage to evolve independently as the DUT becomes more complex.

## 10. Scope

The DUT is intentionally a simplified memory controller.

It does not implement a physical DDR interface or a complete DDR PHY architecture.

Instead, the project focuses on verification concepts applicable to larger digital IP environments, including:

- synchronous interface verification
- transaction-based stimulus
- constrained-random testing
- functional coverage
- self-checking scoreboards
- assertion-based verification
- regression automation
- debug of clocked DUT behavior
