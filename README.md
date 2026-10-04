# UVM Verification Environment for an AXI4-Lite to APB Bridge

A UVM 1.2 environment for a synthesizable Verilog AXI4-Lite to APB bridge. It has an AXI4-Lite master agent, a reactive APB slave agent with random wait states and error injection, a scoreboard and functional coverage, and it runs in Vivado XSim using the built-in UVM library.

---

## Design under test

`rtl/axi_to_apb_bridge.v` converts the five-channel AXI4-Lite slave interface into a single APB master interface. It is parameterized by `ADDR_WIDTH` and `DATA_WIDTH` (both 32 by default) with clock `aclk` and active-low reset `aresetn`.

```text
ST_IDLE ──► ST_APB_SETUP ──► ST_APB_ACCESS ──► ST_AXI_WRESP ──┐
   ▲                               │                           │
   │                               └───────► ST_AXI_RRESP ─────┤
   └───────────────────────────────────────────────────────────┘
```

- A write starts when `AWVALID` and `WVALID` are both high, a read when `ARVALID` is high. A write wins if both arrive together.
- Each transaction becomes a two-phase APB transfer. The transfer completes only when `PREADY` is high while `PENABLE` is already high on the bus.
- `PSLVERR=1` becomes AXI `SLVERR` (`2'b10`), otherwise `OKAY` (`2'b00`). `WSTRB` is forwarded to `PSTRB`.
- One transaction is handled at a time. `awprot` and `arprot` are accepted and ignored, and there is no `PPROT` or timeout.

---

## Architecture

```text
tb_top
 ├── clock / reset, axi_lite_if, apb_if
 ├── DUT: axi_to_apb_bridge
 └── axi_to_apb_base_test
      └── axi_to_apb_env
           ├── axi_lite_agent  (active)
           │    ├── sequencer
           │    ├── driver ───────────► axi_lite_if ──► DUT
           │    └── monitor ──┬──► scoreboard
           │                  └──► coverage
           ├── apb_agent       (active, reactive slave)
           │    ├── slave driver ◄───── apb_if ◄── DUT
           │    └── monitor ──────────► scoreboard
           ├── axi_to_apb_scoreboard
           └── axi_to_apb_coverage
```

All source files are in [`uvm/`](uvm/).

| Component | File | Role |
|-----------|------|------|
| Interfaces | `axi_lite_if.sv`, `apb_if.sv` | Signal bundles with driver and monitor clocking blocks |
| Sequence items | `axi_lite_seq_item.sv`, `apb_seq_item.sv` | AXI transaction (op, address, data, strobes, delays, response) and APB slave knobs (`wait_cycles`, `inject_err`) |
| AXI-Lite master agent | `axi_lite_driver.sv`, `axi_lite_monitor.sv`, `axi_lite_agent.sv` | Drives one read or write at a time. The monitor reports each completed transaction at the `B` or `R` handshake |
| APB slave agent | `apb_slave_driver.sv`, `apb_monitor.sv`, `apb_agent.sv` | Reactive slave: waits for the setup phase, inserts random wait cycles, optionally returns `PSLVERR`, and serves reads from a sparse memory. The monitor reports every completed APB transfer |
| Scoreboard | `axi_to_apb_scoreboard.sv` | Pairs each AXI transaction with the APB transfer it produced and checks it |
| Coverage | `axi_to_apb_coverage.sv` | Functional coverage on AXI-side transactions |
| Sequences | `axi_lite_seq_lib.sv` | `axi_lite_write_readback_seq` and `axi_lite_random_seq` |
| Test and top | `axi_to_apb_base_test.sv`, `tb_top.sv` | One test, 100 MHz clock, reset, interface wiring |

---

## Stimulus

- **Directed:** a write followed by a read of the same address, at `0x1000` and `0x2004`.
- **Constrained random:** 30 read/write transactions with random word-aligned addresses, random data, and a random delay of 0 to 5 cycles before each transaction.
- **APB slave behavior:** every transfer gets a random wait-state count from 0 to 8, and about 15% of transfers return `PSLVERR`. A write that returns an error does not update the slave memory.

In total the test sends 34 transactions (4 directed, 30 random). Error injection applies to every APB transfer, including the directed ones, so a directed write can itself return `SLVERR` and leave the slave memory unchanged.

## Checks

The scoreboard matches AXI and APB items in order and checks, for every transaction:

1. **Direction:** an AXI write produces an APB write, and a read produces a read
2. **Address:** `awaddr`/`araddr` equals `paddr`
3. **Write data:** `wdata` equals `pwdata`
4. **Read data:** `rdata` equals `prdata` (skipped when the transfer returned an error)
5. **Error mapping:** `PSLVERR=1` gives AXI `SLVERR` (`2'b10`)

The check is a pass-through check on the bridge. It does not compare read data against earlier writes, because the slave model already provides the data that comes back. At the end it prints a summary and ends with `uvm_fatal` if any check failed.

## Functional coverage

The covergroup samples every completed AXI transaction:

- operation (read, write)
- response (`OKAY`, `SLVERR`)
- address zone (`0x0000_0000` to `0x0000_0FFF`, `0x0000_1000` to `0x0000_FFFF`, above `0x0001_0000`)
- cross of operation and response

---

## Results

The test runs to completion and ends at 3825 ns. UVM report summary from the console:

```text
--- UVM Report Summary ---

** Report counts by severity
UVM_INFO :   16
UVM_WARNING :    0
UVM_ERROR :    0
UVM_FATAL :    0
** Report counts by id
[FINAL_STATUS]     3
[RNTST]     1
[SCB_REPORT]     4
[TEST]     2
[TEST_DONE]     1
[UVM/COMP/NAMECHECK]     1
[UVM/RELNOTES]     1
[UVMTOP]     1
[axi_lite_random_seq]     2

$finish called at time : 3825 ns
```

Zero errors and zero fatals. The scoreboard's pass banner printed (the three `FINAL_STATUS` lines), and its failure path would have raised a `UVM_FATAL` instead.

### Waveforms

AXI write channels over the full run. `BRESP` shows `2` (`SLVERR`) when the slave injects an error:

![AXI write channels](uvm/waves/uvm_waveform1.png)

AXI read channels and the APB bus. Reads of addresses that were never written return `deadbeef` from the slave model:

![AXI read channels and APB bus](uvm/waves/uvm_waveform2.png)

APB response signals and the bridge state. `PREADY` drops for the slave's random wait states, and `PSLVERR` pulses on the injected errors:

![APB responses and FSM state](uvm/waves/uvm_waveform3.png)

A waveform configuration for the signals used in debugging is in [`uvm/waves/axi_to_apb_uvm_waves.wcfg`](uvm/waves/axi_to_apb_uvm_waves.wcfg).

---

## Not covered yet

- **One transaction at a time.** The AXI driver waits for each response before starting the next, so there are no back-to-back or simultaneous read and write requests.
- **AW and W on the same cycle.** The address and data channels are always driven together.
- **WSTRB is always `4'hF`,** and the scoreboard does not check `PSTRB`.
- **`BREADY` and `RREADY` are asserted early** in every transaction, so response backpressure is not exercised.
- **Read-side `SLVERR` was not hit in the captured run.** Error injection is random, and in the waveform above only writes received errors (`RRESP` stays `0`).
- **Address-zone coverage is not closed.** Random 32-bit addresses almost always land in the highest zone, so the lowest zone is never hit.
- **Scoreboard gaps.** It does not check that a transfer without `PSLVERR` returns `OKAY`, and it does not flag unmatched items left in its queues at the end of the test.
- **No reset during a transaction.**
- **A single test with a default seed.** No seed sweep or multiple test variants.
- **No protocol assertions** in the interfaces, and no coverage of APB wait-state counts.

---

## Running it

1. Add `rtl/axi_to_apb_bridge.v` and `uvm/tb_top.sv` as simulation sources. `tb_top.sv` includes all the other files, so add the `uvm/` folder as an include directory.
2. Set `tb_top` as the simulation top and enable Vivado's built-in UVM library (`-L uvm`) in the simulation settings.
3. Run Behavioral Simulation with `run all`. The test is hard-coded to `axi_to_apb_base_test` and ends itself.

## Repository layout

```text
├── rtl/
│   └── axi_to_apb_bridge.v
├── tb/
│   ├── axi_lite_if.sv, apb_if.sv
│   ├── axi_lite_seq_item.sv, axi_lite_seq_lib.sv
│   ├── axi_lite_driver.sv, axi_lite_monitor.sv, axi_lite_agent.sv
│   ├── apb_seq_item.sv, apb_slave_driver.sv, apb_monitor.sv, apb_agent.sv
│   ├── axi_to_apb_scoreboard.sv, axi_to_apb_coverage.sv
│   ├── axi_to_apb_env.sv, axi_to_apb_base_test.sv, tb_top.sv
|──sim/  (waveform config and screenshots)
├── LICENSE
└── README.md
