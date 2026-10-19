# Full-Flow ASIC Implementation of 32-bit RISC-V Core (SkyWater 130nm)

[![License](https://img.shields.io/badge/License-Apache%202.0%20%2F%20ISC-blue.svg)](LICENSE)
[![PDK](https://img.shields.io/badge/PDK-SkyWater%20130nm-orange.svg)](https://github.com/google/skywater-pdk)
[![Flow](https://img.shields.io/badge/Flow-OpenLane%20%2F%20OpenROAD-green.svg)](https://github.com/The-OpenROAD-Project/OpenLane)
[![CI Verification](https://github.com/vn-ntd/riscv_picorv32_sky130_asic_flow/actions/workflows/verify_metrics.yml/badge.svg)](https://github.com/vn-ntd/riscv_picorv32_sky130_asic_flow/actions/workflows/verify_metrics.yml)
[![DRC](https://img.shields.io/badge/Magic%20DRC-Clean%20(0%20violations)-brightgreen.svg)]()
[![LVS](https://img.shields.io/badge/Netgen%20LVS-Clean%20(100%25%20Matched)-brightgreen.svg)]()
[![Antenna Status](https://img.shields.io/badge/Antenna%20Nets-21%20violations-yellow.svg)]()

This repository contains the complete **RTL-to-GDSII Physical Implementation** of a 32-bit RISC-V CPU core (**PicoRV32**) synthesized on the **SkyWater 130nm (`sky130_fd_sc_hd`)** open-source process design kit using the **OpenLane / OpenROAD** flow.

The implementation is **signoff-clean at the OpenLane block/macro level** (hardened core macro ready for SoC integration or Caravel padframe wrapping), with 100% clean Magic DRC, 100% Netgen LVS netlist matching, and timing closure at **133.33 MHz** (Nominal PVT corner).

---

## 📊 Comprehensive PPA & Physical Signoff Metrics

The table below contrasts the initial exploratory baseline run against the final PPA-optimized implementation, extracted directly from post-routing signoff reports (`reports/metrics.csv`, `reports/29-rcx_sta.summary.rpt`, `reports/drc.rpt`, `reports/37-picorv32.lef.lvs.log`):

| Category | Metric | Baseline Run | Optimized Final | Engineering Analysis & Notes |
| :--- | :--- | :---: | :---: | :--- |
| **Architecture** | Target Architecture | RISC-V RV32I | RISC-V RV32I | 32-bit CPU with full 32×32b register file |
| | PDK Technology | SkyWater 130nm | SkyWater 130nm | `sky130_fd_sc_hd` standard cell library |
| **Logic & Placement** | Synthesized Logic Cells | 9,442 cells | 9,442 cells | Logic gates, DFFs, Muxes from Yosys |
| | Post-PnR Logic + Buffers | 11,141 cells | **11,174 cells** | Includes 1,732 resizer & CTS buffer insertions |
| | Antenna Diodes | 218 cells | **167 cells** | Inserted by TritonRoute antenna repair |
| | Welltap Cells | 2,623 cells | **2,073 cells** | Latchup prevention tap cells |
| | Decap Cells | 6,154 cells | **2,846 cells** | Decoupling capacitors for IR-drop mitigation |
| | Filler Cells | 4,377 cells | **3,658 cells** | Standard cell row continuity fillers |
| | **Total Physical Cell Instances** | **24,513 cells** | **19,918 cells** | Exact sum: $11,174 + 167 + 2,073 + 2,846 + 3,658$ |
| | Clock Sinks (Flip-Flops) | 1,596 sinks | **1,596 sinks** | Regfile (32×32b) + PC + pipeline DFFs |
| | CTS Leaf Buffers | 168 buffers | **155 buffers** | TritonCTS clustered leaf drivers (`clkbuf_leaf_*`) |
| | LVS Total Nets | 11,284 nets | **11,317 nets** | +33 nets from diode insertions and tap rails |
| **Area & Density** | **Core Area** | 182,491 µm² | **147,310 µm²** | **19.3% core area reduction** ($383.8 \times 383.8\,\mu\text{m}$) |
| | **Die Area** | 0.1969 mm² | **0.1606 mm²** | **18.5% die area reduction** ($400.7 \times 400.7\,\mu\text{m}$) |
| | Core-to-Die Margin | 8.46 µm | 8.46 µm | IO & power ring boundary halo |
| | **Core Utilization** | 56.43% | **69.93% (~70%)** | **+13.50 percentage points denser** |
| | Total Wire Length | 519,269 µm | **511,143 µm** | Interconnect length reduced by ~8.1 mm |
| **Timing (STA)** | Target Clock Period | 15.00 ns (66.67 MHz) | **7.50 ns (133.33 MHz)** | **2× operational clock frequency** |
| | Setup Slack Margin (`tt`) | +6.08 ns (Met) | **+0.07 ns (Met)** | Positive margin at target frequency (post-SPEF) |
| | Setup WNS / TNS (`tt`) | 0.00 ns / 0.00 ns | **0.00 ns / 0.00 ns** | **Zero Negative Slack (Met at nominal corner)** |
| | Hold Slack Margin (`tt`) | +0.15 ns (Met) | **+0.30 ns (Met)** | Positive hold margin across all register paths |
| | Hold WNS / TNS (`tt`) | 0.00 ns / 0.00 ns | **0.00 ns / 0.00 ns** | **Zero Negative Slack (Clean)** |
| | Slow Corner Max Path (`ss`) | 8.92 ns | **8.27 ns** | Worst-case path delay at `ss_100C_1v60` corner |
| | Slow Corner Setup Slack | +6.08 ns (at 15ns) | **-0.77 ns (at 7.5ns)** | Closes at **120.9 MHz** ($T \ge 8.27\,\text{ns}$) across SS |
| | Clock Tree Skew | 110 ps | **110 ps** | Balanced 3-level tree (`CTS_TARGET_SKEW = 100ps`) |
| **Power (OpenSTA)** | Internal Power | 15.8 mW | **24.2 mW** | Cell internal charging (52.7% of total) |
| | Switching Power | 14.1 mW | **21.7 mW** | Interconnect net switching (47.3% of total) |
| | Leakage Power | 46.4 nW | **59.1 nW** | Subthreshold and gate leakage (< 0.001%) |
| | **Total Power Consumption** | **29.9 mW** @ 66.7MHz | **45.9 mW** @ 133.3MHz | Estimated via OpenSTA static analysis (1.80V, 25°C) |
| | Energy per Cycle | 448 pJ / cycle | **344 pJ / cycle** | **23.2% more energy-efficient** |
| **Physical Signoff** | Detailed Routing DRC | 0 violations | **0 violations** | Zero shorts, spacing, or min-hole violations |
| | Magic DRC Signoff | 0 violations | **0 violations** | 100% clean on final GDSII layout stream |
| | Netgen LVS Verification | 100% Matched | **100% Matched** | `Circuits match uniquely` (11,317/11,317 nets) |
| | Antenna Violations (ARC) | 28 nets / 33 pins | **21 nets / 22 pins** | Global router jumper repair status (see details) |
| | KLayout DRC / CVC | N/A (-1) | N/A (-1) | Magic DRC is primary signoff engine on Sky130 |

> **Transparency Note on Baseline:**  
> The baseline values are recorded from intermediate exploratory run `run_clean_baseline`. The full set of physical signoff artifacts and reports committed in this repository corresponds directly to the final optimized implementation `run_final_68util_7p5ns`.

---

## 🔍 Detailed Multi-Corner Timing Analysis

To ensure complete technical rigor and avoid ambiguity regarding timing closure:

### 1. Difference Between Slack (Margin) and WNS (Worst Negative Slack)
* **Worst Slack (Margin):** The actual timing margin relative to clock required time.
  * Setup Margin = $\text{Required Time} - \text{Arrival Time} = +0.07\,\text{ns}$ at Nominal PVT corner.
  * Hold Margin = $\text{Arrival Time} - \text{Required Time} = +0.30\,\text{ns}$.
* **WNS (Worst Negative Slack):** Standard EDA metric defined as $\min(0, \text{Slack})$. When all timing constraints are met with non-negative slack, **WNS = 0.00 ns** and **TNS = 0.00 ns**.

### 2. Multi-Corner STA (PVT Corners) Breakdown
Signoff timing analysis was performed using OpenSTA across multi-corner SPEF parasitic extractions:

| Corner Name | Process Corner | Voltage | Temp | Max Data Path Delay | Setup Status at 7.50 ns (133.33 MHz) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Nominal (`nom`)** | Typical (`tt`) | 1.80 V | 25 °C | **7.33 ns** (pre-route) / **7.43 ns** (post-SPEF) | **MET (Slack: +0.07 ns, WNS: 0.00 ns)** |
| **Slow (`max`)** | Slow-Slow (`ss`) | 1.60 V | 100 °C | **8.27 ns** | **Violated at 7.5ns (Slack: -0.77 ns)**<br>Closes timing at **120.9 MHz** ($T \ge 8.27\,\text{ns}$) |
| **Fast (`min`)** | Fast-Fast (`ff`) | 1.95 V | -40 °C | **4.91 ns** | **MET (Hold Margin: +0.30 ns)** |

* **Timing Closure Scope:** The core achieves complete timing closure at **133.33 MHz (7.50 ns)** under Nominal conditions (`tt_025C_1v80`). When derated for the worst-case industrial Slow corner (`ss_100C_1v60`, high junction temperature and IR-drop derating), the maximum operating frequency is **120.9 MHz (8.27 ns)**.

### 3. Critical Path Breakdown (Nominal Corner, `13-cts_sta.log`)
```text
Startpoint: _16057_ (rising edge-triggered flip-flop clocked by clk)
Endpoint:   _16118_ (rising edge-triggered flip-flop clocked by clk)
---------------------------------------------------------------------
Launch Clock Latency:       0.88 ns (via clkbuf_0_clk -> clkbuf_4_0_0_clk -> clkbuf_leaf_3_clk)
Combinational Logic Delay:  6.45 ns (through 32-bit counter & ALU decode gates)
Total Data Arrival Time:    7.33 ns

Clock Edge:                 7.50 ns
Capture Clock Latency:      0.79 ns
Clock Uncertainty:         -0.25 ns
Clock Reconvergence (CRPR): +0.07 ns
Library Setup Time:        -0.10 ns
Total Data Required Time:   8.01 ns
---------------------------------------------------------------------
Setup Slack (Margin):      +0.68 ns (pre-route) -> +0.07 ns (post-SPEF signoff)
```

---

## 🔬 Architectural & Physical Design Highlights

### 1. Register File Architecture & Clock Sinks (1,596 DFFs)
* PicoRV32 implements thirty-two 32-bit general-purpose registers (`cpuregs`), CPU program counter, instruction buffers, and performance counters directly as standard D flip-flops (`sky130_fd_sc_hd__df*`).
* **Total Flip-Flop Count:** Exactly **1,596 DFFs** (clock sinks).
* **CTS Clustering:** TritonCTS clustered the 1,596 DFFs into localized groups of ~10–12 sinks and synthesized a 3-level balanced clock tree driven by **155 leaf clock buffers** (`clkbuf_leaf_*`).
* **Clock Skew:** Constrained to **110 ps** across all 1,596 sinks.

### 2. PDN Optimization & Congestion Resolution
* **The Problem:** Initial strap pitch of 25 µm blocked over 50% of routing tracks on Metal 4 & Metal 5, triggering catastrophic routing congestion during Global Routing (`ERROR GRT-0119`).
* **The Solution:** Adjusted strap pitch to standard **153.6 µm** (`FP_PDN_VPITCH = 153.6 µm`, `FP_PDN_HPITCH = 153.18 µm`) and eliminated artificial cell padding. This restored routing track availability and enabled routing with **0 DRC violations** at **70% core utilization**.

### 3. Antenna Effect Status & Analysis
* Blindly inserting pre-routing diodes (`RUN_HEURISTIC_DIODE_INSERTION = 1`) flooded the core with 3,555 diode cells, causing legalization failures (`ERROR DPL-0036`).
* Replaced heuristic insertion with pure **Global Router Antenna Repair (`GRT_REPAIR_ANTENNAS = 1`)**, allowing TritonRoute to create metal jumpers and insert 167 targeted diodes.
* **Current Status:** 21 net violations (22 pin violations) remain on long interconnects. For full tapeout signoff, inserting port diodes (`DIODE_ON_PORTS = "both"`) or running additional repair iterations (`GRT_ANTENNA_ITERS = 20`) is recommended.

### 4. Power Analysis Disclaimer
* Power numbers (Total: 45.9 mW, Internal: 24.2 mW, Switching: 21.7 mW, Leakage: 59.1 nW) were estimated via OpenSTA Static Power Analysis using default standard cell toggle rate assumptions (0.1 toggle probability, 0.5 static duty cycle at 1.80V, 25°C), not from dynamic activity vectors from VCD simulation.

---

## 🧪 Functional Verification & Simulation

A self-checking Verilog testbench (`tb/picorv32_tb.v`) is included to verify the RTL and gate-level netlists. The testbench models 64 KB of memory and executes a suite of RV32I instructions:
* **Arithmetic:** `ADDI`, `ADD`, `SUB`
* **Bitwise Logic:** `AND`, `OR`, `XOR`
* **Shifts & Comparison:** `SLLI`, `SRLI`, `SLT`
* **Memory Access:** Word store (`SW`) and load (`LW`)
* **Branching & Control:** `BEQ`, `BNE`, `JAL` with an iterative summation loop ($\sum_{i=1}^{5} i = 15$)

### Running Simulation (Icarus Verilog):
```bash
# RTL Simulation
iverilog -o simv -s picorv32_tb src/picorv32a.v tb/picorv32_tb.v
vvp simv

# Expected Output:
# [SIMULATION SUCCESS] RISC-V PicoRV32 Verification PASSED!
# - Arithmetic: ADDI, ADD, SUB           -> PASS
# - Bitwise Logic: AND, OR, XOR          -> PASS
# - Shift / Compare: SLLI, SRLI, SLT     -> PASS
# - Memory Access: SW, LW, BEQ           -> PASS
# - Iterative Summation Loop: BNE, JAL   -> PASS (Sum 1..5 = 15)
```

---

## 📁 Repository Structure

```
.
├── .github/workflows/
│   └── verify_metrics.yml     # Automated CI checking RTL simulation and signoff metrics
├── config/
│   └── config.tcl             # Optimized OpenLane flow configuration
├── src/
│   ├── picorv32a.v            # RISC-V RV32I CPU core RTL source
│   └── constraints.sdc        # SDC timing constraints (clock period, uncertainty, IO delay)
├── tb/
│   ├── picorv32_tb.v          # Self-checking functional testbench
│   └── run_sim.sh             # Simulation execution script (supports RTL and GLS)
├── results/
│   ├── picorv32.gds           # Final GDSII layout stream (31.26 MB, Git LFS)
│   ├── picorv32.gds.gz        # Compressed GDSII layout stream (6.0 MB)
│   ├── picorv32.def           # Placed and routed DEF file (11.7 MB)
│   ├── picorv32.v             # Final powered gate-level netlist (GLS)
│   ├── picorv32.spef          # RC parasitic extraction file (14.9 MB)
│   ├── picorv32.sdc           # Signoff SDC constraints
│   └── picorv32.spice         # Extracted SPICE netlist for LVS
├── reports/
│   ├── metrics.csv            # Complete PPA data measurements table
│   ├── manufacturability.rpt  # Signoff DRC / LVS / Antenna summary
│   ├── drc.rpt                # Magic DRC 0-violation report
│   ├── 37-picorv32.lef.lvs.log# Netgen LVS exact matching log
│   ├── 29-rcx_sta.summary.rpt # STA slack summary
│   ├── 29-rcx_sta.checks.rpt  # Slew, fanout, and capacitance checks
│   ├── 12-cts.log             # Clock tree synthesis structure log
│   └── 13-cts_sta.log         # Post-CTS timing and critical path log (9.7 MB)
├── scripts/
│   ├── run_flow.sh            # Fully portable OpenLane containerized runner script
│   └── export_layout_image.py # Automated KLayout layout render export script
├── .gitattributes             # Git LFS configuration
├── LICENSE                    # Full Apache-2.0 & ISC License details
└── README.md
```

---

## 🔧 Environment & Tool Versions

To ensure deterministic reproducibility:

* **OpenLane Version:** `v1.0.2` (commit `ff5509f65b17bfa4068d5336495ab1718987ff69`)
* **OpenROAD Version:** Commit `41a51eaf4ca2171c92ff38afb91eb37bbd3f36da`
* **Synthesis Tool:** Yosys `0.27+`
* **Physical DRC Tool:** Magic `8.3.453`
* **Physical LVS Tool:** Netgen `1.5.250`
* **Layout Viewer:** KLayout `0.26.2`
* **Process Design Kit:** SkyWater 130nm (`sky130A`, commit `0fe599b2afb6708d281543108caf8310912f54af`)
* **Docker Image:** `ghcr.io/the-openroad-project/openlane:ff5509f65b17bfa4068d5336495ab1718987ff69-amd64`

---

## 🚀 How to Reproduce

### 1. Clone Repository
```bash
git clone https://github.com/vn-ntd/riscv_picorv32_sky130_asic_flow.git
cd riscv_picorv32_sky130_asic_flow
```

### 2. Run OpenLane Flow
```bash
# Uses portable scripts/run_flow.sh (supports $OPENLANE_ROOT and $PDK_ROOT)
./scripts/run_flow.sh run_reproduce -overwrite
```

### 3. View GDSII Layout in KLayout
```bash
# Decompress layout stream if needed
gzip -dk results/picorv32.gds.gz

# Open in KLayout with Sky130 technology mapping
klayout -e -nn ~/.ciel/sky130A/libs.tech/klayout/tech/sky130A.lyt \
        results/picorv32.gds
```
*(Press **F** in KLayout to fit the entire $383.8\,\mu\text{m} \times 383.8\,\mu\text{m}$ core to screen).*

---

## 📄 License & Attribution
* **Core RTL:** PicoRV32 by Claire Wolf (ISC License).
* **ASIC Flow & PDK:** OpenLane & SkyWater 130nm (Apache 2.0 License).
* **Implementation Scripts & Testbench:** Copyright (c) 2026 Tien Dung Nguyen (Apache 2.0 License).
