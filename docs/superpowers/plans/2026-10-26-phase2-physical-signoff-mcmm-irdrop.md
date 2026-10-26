# Phase 2: Physical Signoff Elevation (Multi-Corner STA & Power Grid IR-Drop) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Elevate physical design signoff from single-corner nominal metrics to comprehensive multi-corner STA (PVT corners `ss_100C_1v60`, `tt_025C_1v80`, `ff_n40C_1v95`), perform static IR-drop power grid integrity analysis on `VPWR` and `VGND`, generate SDF timing delay views, and integrate into the master Makefile.

**Architecture:** 
OpenSTA scripts (`scripts/sta_mcmm.tcl`) analyze the post-routing netlist (`results/picorv32.v`) and parasitics (`results/picorv32.spef`) against Sky130 standard cell timing libraries across three operational corners to determine true silicon Fmax and hold safety. An OpenROAD script (`scripts/irdrop.tcl`) analyzes the PDN mesh on `results/picorv32.def` to quantify IR drop across core coordinates. Portable runner wrappers (`scripts/run_sta_mcmm.sh`, `scripts/run_irdrop.sh`) support both local EDA tools and containerized Docker environments. Master `Makefile` exposes `make sta-mcmm`, `make irdrop`, and `make sdf`.

**Tech Stack:** OpenSTA, OpenROAD, SkyWater 130nm PDK (`sky130_fd_sc_hd`), Tcl, Bash, Python 3, Make.

**Spec:** Roadmapped in initial audit discussion (Phase 2: Physical Signoff Elevation).

## Global Constraints
- Target PDK: SkyWater 130nm (`sky130A`, library `sky130_fd_sc_hd`).
- Operating corners:
  - Slow (`ss`): $1.60\,\text{V}, 100^\circ\text{C}$ (`sky130_fd_sc_hd__ss_100C_1v60.lib`) -> Worst-case setup signoff.
  - Typical (`tt`): $1.80\,\text{V}, 25^\circ\text{C}$ (`sky130_fd_sc_hd__tt_025C_1v80.lib`) -> Nominal reference.
  - Fast (`ff`): $1.95\,\text{V}, -40^\circ\text{C}$ (`sky130_fd_sc_hd__ff_n40C_1v95.lib`) -> Worst-case hold signoff.
- Target clock period: $7.5\,\text{ns}$ ($133.33\,\text{MHz}$).
- Power grid nets: `VPWR` ($1.8\,\text{V}$) and `VGND` ($0.0\,\text{V}$).
- Static IR-drop threshold: Worst drop should be $\le 5\%$ to $10\%\,V_{DD}$ ($< 90\,\text{mV}$).

## Review Focus
1. Library mapping: Verify exact library paths for `ss`, `tt`, `ff` corners in standard Sky130 PDK distributions.
2. Setup slack at slow corner: Quantify how much setup slack decreases at `ss_100C_1v60` and compute true derated Fmax.
3. Hold slack at fast corner: Verify hold margins at `ff_n40C_1v95` remain strictly positive ($> 0\,\text{ns}$).
4. IR drop convergence: Ensure `analyze_power_grid` finds appropriate voltage sources on Metal 5 straps.
5. Reference reporting: Generate clear markdown/text summaries in `reports/` for instant inspection.

---

### Task 1: Multi-Corner STA (MCMM) & SDF Generation

**Files:**
- Create: `scripts/sta_mcmm.tcl`
- Create: `scripts/run_sta_mcmm.sh`
- Create: `reports/sta_mcmm_summary.rpt`
- Produces: `results/picorv32.sdf`

**Interfaces:**
- Consumes: `results/picorv32.v`, `results/picorv32.spef`, `results/picorv32.sdc`
- Produces: Multi-corner timing reports and `results/picorv32.sdf`

- [ ] **Step 1: Write `scripts/sta_mcmm.tcl`**
Implement corner sweep across `ss`, `tt`, `ff`. In each iteration: read standard cell library, link design `picorv32`, read SPEF parasitics, read SDC constraints, report worst setup and hold slacks, compute Fmax, and write SDF.

- [ ] **Step 2: Write `scripts/run_sta_mcmm.sh`**
Create containerized/local runner script mounting repo directory and PDK root, executing OpenSTA.

- [ ] **Step 3: Generate reference report `reports/sta_mcmm_summary.rpt`**
Provide detailed analysis of arrival times, required times, slack margins, and Fmax across all 3 corners.

---

### Task 2: IR-Drop & Power Grid Integrity Analysis

**Files:**
- Create: `scripts/irdrop.tcl`
- Create: `scripts/run_irdrop.sh`
- Create: `reports/irdrop_summary.rpt`

**Interfaces:**
- Consumes: `results/picorv32.def`, `results/picorv32.spef`, `results/picorv32.sdc`
- Produces: Voltage drop and current distribution reports on `VPWR` and `VGND`

- [ ] **Step 1: Write `scripts/irdrop.tcl`**
Implement OpenROAD script loading technology LEF, cell LEF, DEF, SDC, and SPEF. Run `analyze_power_grid -net VPWR` and `analyze_power_grid -net VGND`.

- [ ] **Step 2: Write `scripts/run_irdrop.sh`**
Create runner script for Docker / local OpenROAD.

- [ ] **Step 3: Generate reference report `reports/irdrop_summary.rpt`**
Document worst-case IR drop, average drop, and percentage drop relative to 1.8V VDD.

---

### Task 3: Top-Level Makefile Integration

**Files:**
- Modify: `Makefile`

**Interfaces:**
- Consumes: `scripts/run_sta_mcmm.sh`, `scripts/run_irdrop.sh`
- Provides: `make sta-mcmm`, `make irdrop`, `make sdf`

- [ ] **Step 1: Add targets `sta-mcmm`, `irdrop`, and `sdf` to root `Makefile`**
- [ ] **Step 2: Verify `make help` displays new commands**

---

### Task 4: Documentation & Signoff Update

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update `README.md` with Multi-Corner STA section and table**
- [ ] **Step 2: Update `README.md` with Power Grid Integrity & IR-Drop section**
- [ ] **Step 3: Verify markdown formatting and commit Phase 2**
