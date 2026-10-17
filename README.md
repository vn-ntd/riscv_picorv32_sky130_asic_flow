# Full-Flow ASIC Implementation of 32-bit RISC-V Core (SkyWater 130nm)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![PDK](https://img.shields.io/badge/PDK-SkyWater%20130nm-orange.svg)](https://github.com/google/skywater-pdk)
[![Flow](https://img.shields.io/badge/Flow-OpenLane%20%2F%20OpenROAD-green.svg)](https://github.com/The-OpenROAD-Project/OpenLane)
[![DRC](https://img.shields.io/badge/DRC-Clean%20(0%20violations)-brightgreen.svg)]()
[![LVS](https://img.shields.io/badge/LVS-Clean%20(100%25%20Matched)-brightgreen.svg)]()
[![Timing](https://img.shields.io/badge/WNS-0.00ns%20(Met)-brightgreen.svg)]()

This repository contains the complete, production-ready **RTL-to-GDSII Physical Implementation** of a 32-bit RISC-V CPU core (**PicoRV32**) synthesized on the **SkyWater 130nm (`sky130_fd_sc_hd`)** open-source process design kit using the **OpenLane / OpenROAD** flow.

---

## ?? Key PPA & Signoff Results

| Metric | Initial Baseline | Optimized Final | Improvement |
| :--- | :---: | :---: | :---: |
| **Core Architecture** | RISC-V RV32I | RISC-V RV32I | 32-bit Standard ISA |
| **PDK Technology** | SkyWater 130nm | SkyWater 130nm | High Density Standard Cells |
| **Standard Cell Count** | 9,442 cells | 9,442 cells | Gates, DFFs, Multiplexers |
| **Core Utilization** | 56.43% | **69.93% (~70%)** | **+13.5% denser utilization** |
| **Die Area** | 0.197 mm? (182,491 ?m?) | **0.161 mm? (147,310 ?m?)** | **18.5% silicon area reduction** |
| **Die Dimensions (W ? H)**| 427.2 ?m ? 427.2 ?m | **383.8 ?m ? 383.8 ?m** | Square (Aspect Ratio 1.0) |
| **Total Wire Length** | 519,269 ?m | **511,143 ?m** | Shorter interconnects |
| **Target Frequency** | 66.7 MHz (15.0 ns) | **133.33 MHz (7.50 ns)** | **2? faster operational clock** |
| **Critical Path Delay** | 8.92 ns | **8.27 ns** | 0.65 ns delay reduction |
| **Worst Negative Slack (WNS)** | 0.00 ns | **0.00 ns** | **Zero Negative Slack (Setup Slack: +0.07 ns)** |
| **Total Negative Slack (TNS)** | 0.00 ns | **0.00 ns** | **Zero Negative Slack (Hold Slack: +0.30 ns)** |
| **Clock Skew (CTS)** | 110 ps | **110 ps** | Balanced 3-level tree |
| **Detailed Routing DRC** | 0 errors | **0 errors** | Zero shorts, spacing, min-hole |
| **Magic DRC Signoff** | 0 errors | **0 errors** | 100% DRC clean on GDSII |
| **LVS Net Matching** | 11,284 / 11,284 | **11,317 / 11,317** | **100% matched uniquely** |
| **Tapeout GDSII File** | 30.06 MB | **31.26 MB** | Ready for fabrication |

---

## ??? Physical Design & Engineering Highlights

### 1. Floorplanning & Power Distribution Network (PDN)
* Designed a symmetric square floorplan with **Aspect Ratio = 1.0**.
* Constructed a robust, low IR-drop power grid utilizing top metal layers: **Metal 4 (Vertical Straps)** and **Metal 5 (Horizontal Straps)**.
* **Engineering Challenge & Fix:** Initial strap spacing of 25 ?m choked metal resources (causing routing congestion). Recalibrated PDN strap pitch to **153.6 ?m** (Sky130 standard), restoring 40% of routing tracks and enabling flawless 70% core utilization.

### 2. Placement & Timing Optimizations
* Solved local pin density spikes around the RISC-V Register File and ALU multiplexers by removing artificial cell padding, allowing OpenROAD Detailed Placer (DPL) to legalize cells without overflow.
* Integrated pre-CTS and post-CTS Resizer optimizations (`PL_RESIZER_TIMING_OPTIMIZATIONS = 1`) to eliminate hold violations early.

### 3. Clock Tree Synthesis (CTS)
* Synthesized an H-Tree topology using TritonCTS with dedicated clock inverter/buffer library (`sky130_fd_sc_hd__clkbuf_8/16`).
* Achieved a symmetrical 3-level buffer tree with **Clock Skew < 110 ps** across 168 leaf sinks.

### 4. Routing, Antenna Repair & Signoff
* Detailed Routing completed with **0 DRC errors** using TritonRoute.
* Replaced destructive pre-routing heuristic diodes with pure **Global Router Antenna Repair (`GRT_REPAIR_ANTENNAS = 1`)**, preventing row legalization saturation while protecting transistor gate oxides.
* **LVS Verification (Netgen):** SPICE netlist extracted from layout silicon matched the gate-level schematic **11,317 nets out of 11,317 (100% matched)** with zero discrepancy.

---

## ?? Repository Structure

```
.
??? config/
?   ??? config.tcl             # Optimized OpenLane flow configuration
??? src/
?   ??? picorv32a.v            # RISC-V RV32I RTL source code
?   ??? constraints.sdc        # Strict SDC timing constraints
??? results/
?   ??? picorv32.gds           # Final GDSII layout stream (31.26 MB)
?   ??? picorv32.gds.gz        # Gzip compressed GDSII (6.0 MB)
?   ??? picorv32.def           # Placed and routed DEF file
?   ??? picorv32.v             # Final powered gate-level netlist
?   ??? picorv32.spef          # RC parasitic extraction file
?   ??? picorv32.sdc           # Signoff SDC constraints
?   ??? picorv32.spice         # Extracted SPICE netlist for LVS
??? reports/
?   ??? metrics.csv            # Full PPA measurement data table
?   ??? manufacturability.rpt  # Signoff DRC / LVS / Antenna summary
?   ??? drc.rpt                # Magic DRC 0-violation signoff report
?   ??? 37-picorv32.lef.lvs.log# Netgen LVS exact matching log
?   ??? 29-rcx_sta.summary.rpt # Static Timing Analysis slack summary
?   ??? 29-rcx_sta.checks.rpt  # Slew, fanout, and capacitance checks
?   ??? 12-cts.log             # Clock tree synthesis structure log
??? scripts/
    ??? run_flow.sh            # One-click execution script
```

---

## ?? How to Reproduce

### Prerequisites
* Linux (Ubuntu 20.04/22.04 or WSL2)
* Docker & Python 3

### Run Full Flow in 1 Command
```bash
git clone https://github.com/vn-ntd/riscv-picorv32-sky130-asic-flow.git
cd riscv-picorv32-sky130-asic-flow

# Launch OpenLane Docker container and run flow
./scripts/run_flow.sh picorv32_custom run_reproduce -overwrite
```

### View GDSII Layout in KLayout
```bash
klayout -e -nn ~/.ciel/sky130A/libs.tech/klayout/tech/sky130A.lyt \
        results/picorv32.gds
```
*(Press **F** to zoom-fit the die).*

---

## ?? License
* Core: PicoRV32 by Claire Wolf (ISC License).
* PDK & Flow: SkyWater 130nm & OpenLane (Apache 2.0 License).
