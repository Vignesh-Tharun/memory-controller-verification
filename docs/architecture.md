# Verification Architecture

## 1. Overview

This project verifies a simplified synchronous memory controller using SystemVerilog and UVM.

The environment separates stimulus generation, DUT driving, observation, checking, coverage, and protocol assertions into dedicated components.

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

The DUT is a 2-stage pipelined synchronous memory controller:

- 256 memory locations, 8-bit address, 32-bit data
- `valid` request signal and `ready` completion signal
- Read or write selected by `write`
- 2-cycle request latency
- Accepts a new request on every clock cycle, even while the previous one is still being processed

**Stage 1 (capture):** an incoming request is latched into `pending` registers.
**Stage 2 (execute):** the pending request is executed (memory write, or memory read into `rdata`) and `ready` is raised.

### Timing of one request

Values driven or registered at a clock edge become visible just after it, and the monitor samples signals just before each edge. This gives the following timeline for one request:

| Edge | DUT | Testbench |
|---|---|---|
| 1 | | Driver drives `valid`, `write`, `addr`, `wdata` |
| 2 | Samples the request into the `pending` registers | Monitor samples the request and queues it |
| 3 | Executes the request, sets `ready` and `rdata` | |
| 4 | | Monitor samples `ready`/`rdata`, removes the request from its queue, and sends the completed transaction to the scoreboard |

The assertion measures the 2-cycle latency between the DUT sampling `valid` (edge 2) and `ready` being sampled (edge 4). With the 10 ns clock used here, a transaction driven at time T is checked by the scoreboard at T + 30 ns.

---

## 3. UVM Environment

### Transaction

`memory_transaction` represents one memory operation:

- `write`, `addr`, `wdata`: randomizable stimulus fields
- `rdata`: filled in by the monitor for reads

### Sequences

- `memory_sequence`: constrained-random writes to ten random addresses, followed by reads of the same addresses (read transactions carry `wdata = 32'hDEADBEEF` as a poison value, so a stray write-data path cannot match by coincidence)
- `write_read_sequence`: one write and one read back to the same address
- `boundary_sequence`: write/read pairs at addresses 0, 100 and 255
- `reset_sequence`: a write/read pair after the initial reset

### Sequencer

Supplies transactions from the sequences to the driver.

### Driver

The driver converts transactions into pin-level activity through a virtual interface and a clocking block. It polls the sequencer every clock cycle with `try_next_item`, drives the request when one is available, and calls `item_done()` immediately after presenting it. This lets the DUT receive a new request every cycle, so back-to-back requests and write-followed-by-read hazards are exercised.

Because `item_done()` fires when a request is presented and not when it completes, each test calls `wait_idle()` after its sequence finishes. The last request needs 3 more cycles to be seen by the monitor (1 for the DUT to sample the driven value, plus the 2-cycle latency), and the drain waits 4 for one cycle of margin.

### Monitor

The monitor passively observes the interface. When it sees `valid`, it creates a transaction and places it in an in-flight queue. When it sees `ready`, it removes the oldest queued transaction, attaches the read data for reads, and sends the completed transaction to the scoreboard through an analysis port.

A FIFO queue is correct here because this DUT gives every request the same fixed latency and completes requests in order. A DUT with variable latency would need matching by transaction ID instead.

At the end of every test, a `check_phase` check reports a `UVM_ERROR` if any transaction is still in the queue. This catches a test that ended before its last transactions completed, or a request the DUT never completed.

### Scoreboard

The scoreboard maintains a reference model of the expected memory contents:

```text
write:  expected_memory[address] = write_data
read:   compare expected_memory[address] with the DUT read data (===)
```

Any mismatch is reported as a `UVM_ERROR`.

---

## 4. Test Scenarios

| Test | Purpose |
|---|---|
| Constrained-random | Random writes, then reads of the same addresses |
| Directed write/read | Known value, known address (10), read back |
| Boundary | Addresses 0, 100 and 255 (LOW, MEDIUM, HIGH regions) |
| Reset recovery | Write/read after the initial reset |

---

## 5. Functional Coverage

Two coverpoints:

- **Operation:** READ, WRITE
- **Address:** LOW (0–63), MEDIUM (64–191), HIGH (192–255)

The covergroup samples only on cycles where `valid` is high, so idle cycles never inflate bin counts. Simple counters also print per-run bin hit counts at the end of each simulation, which were used to check coverage per test.

The final run achieved 100% (5/5 bins). Per-test counters showed that the random test reaches all three address ranges, but only by chance: in one run, only 1 of its 10 random addresses landed in the HIGH range. The directed boundary test makes address-range coverage independent of the random seed.

---

## 6. Assertions

A dedicated assertion module checks request/response timing:

- **Forward check:** `valid` is followed by `ready` exactly 2 cycles later.
- **Reverse check:** every `ready` is preceded by a `valid` 2 cycles earlier, so a response never appears without a request.
- **Cover property:** confirms the forward scenario actually occurs, so the forward check cannot pass vacuously.
- **X/Z check** on `valid` and `ready`. This is only meaningful on 4-state simulators; Verilator is 2-state and cannot produce X or Z.

The scoreboard checks data and the assertions check timing, so each catches bugs the other cannot.

---

## 7. Regression Automation

`tb/uvm/scripts/regression.py` runs the four tests. For each test it requires a zero exit code and checks the UVM report summary for `UVM_ERROR : 0` and `UVM_FATAL : 0`. The script exits with a non-zero status if any test fails.

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
| Functional coverage | 100% (5/5 bins) |
| Assertion failures | 0 |

Negative testing is documented in [bug_injection.md](bug_injection.md).

---

## 9. Known Limitations

- Reset is only applied at the start of simulation. A reset in the middle of an in-flight request is not tested; such a request would be dropped, and the monitor's queue would need to be cleared on reset.
- The timing assertions have so far been run against the fault-free design only.
- One agent, one interface, one clock domain.
- The X/Z check cannot fire under Verilator.

## 10. Scope

The DUT is intentionally a simplified memory controller. It does not implement a physical DDR interface or a DDR PHY, and it does not use DFI. The project focuses on verification methodology that carries over to larger digital IP:

- synchronous interface verification
- transaction-based stimulus
- constrained-random testing
- functional coverage
- self-checking scoreboards
- assertion-based verification
- regression automation
- debug of clocked DUT behavior
