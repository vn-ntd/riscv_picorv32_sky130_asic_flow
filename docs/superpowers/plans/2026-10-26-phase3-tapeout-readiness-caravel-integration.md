# Phase 3: Tapeout Readiness & Efabless Caravel SoC Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete commercial tapeout preparation by providing formal Antenna Waiver documentation for the 21 remaining nets, implementing an Efabless Caravel SoC wrapper module (`src/picorv32_caravel_wrapper.v`), documenting the Shuttle Precheck compliance process, and packaging release artifacts.

**Architecture:** 
A production-ready Verilog wrapper bridges the PicoRV32 CPU core to the Efabless Caravel / ChipIgnite SoC harness via Wishbone bus, Logic Analyzer channels, and GPIOs. A comprehensive Antenna Waiver report (`reports/antenna_waiver.rpt`) provides the technical rationale for Shuttle signoff of boundary nets. A top-level Makefile target standardizes tapeout verification and documentation updates.

**Tech Stack:** Verilog HDL, Efabless Caravel / ChipIgnite architecture, SkyWater 130nm PDK, OpenLane, Make.

**Spec:** Roadmapped in initial audit discussion (Phase 3: Tapeout Readiness).

## Global Constraints
- Target SoC Harness: Efabless Caravel / ChipIgnite (`user_project_wrapper` / `user_proj_example`).
- Bus protocol: Wishbone B4 (Classic / Pipelined compatible).
- Power domain: `vccd1` (1.8V core logic) and `vssd1` (core ground).
- Antenna signoff: Provide verifiable justification for the 21 boundary nets based on top-level ESD diode termination.
- Zero breaking changes to standalone simulation or existing CI checks.

## Review Focus
1. Bus Handshaking: Ensure PicoRV32 `mem_valid`/`mem_ready` protocol bridges correctly to Wishbone `wbs_cyc_i`/`wbs_stb_i`/`wbs_ack_o`.
2. Reset polarity: PicoRV32 uses active-low `resetn`, while Caravel uses active-high `wb_rst_i`. Inversion must be explicit (`resetn = ~wb_rst_i`).
3. Power rail definitions: Ensure `vccd1` and `vssd1` are routed correctly to the core's `VPWR` and `VGND`.
4. CI non-regression: `verify_metrics.yml` must continue to pass cleanly.

---

### Task 1: Antenna Signoff & Formal Waiver Documentation

**Files:**
- Create: `reports/antenna_waiver.rpt`

- [ ] **Step 1: Write `reports/antenna_waiver.rpt`**
Document the 21 nets / 22 pins, classify them as macro-boundary IO nets, demonstrate that internal nets have 0 antenna violations, and explain top-level ESD clamp protection for fab signoff.

---

### Task 2: Efabless Caravel SoC Harness Integration

**Files:**
- Create: `src/picorv32_caravel_wrapper.v`

- [ ] **Step 1: Write `src/picorv32_caravel_wrapper.v`**
Implement the Caravel SoC harness wrapper:
- Power: `vccd1`, `vssd1`
- Clock & Reset: `wb_clk_i`, `wb_rst_i` (with `resetn = ~wb_rst_i`)
- Wishbone bus: `wbs_cyc_i`, `wbs_stb_i`, `wbs_we_i`, `wbs_sel_i`, `wbs_adr_i`, `wbs_dat_i`, `wbs_ack_o`, `wbs_dat_o`
- Logic Analyzer: Map core state, trap, and PC to `la_data_out`
- GPIO: Connect memory-mapped IO port to `io_out` and `io_in`
- Interrupts: Map external IRQ to `user_irq`

---

### Task 3: Makefile & Tapeout Automation Integration

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Add `tapeout-check` target to root `Makefile`**
- [ ] **Step 2: Verify `make help`**

---

### Task 4: Documentation & Tapeout Guide

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add Caravel SoC integration architecture diagram and tapeout checklist to `README.md`**
- [ ] **Step 2: Verify all CI checks pass cleanly and commit Phase 3**
