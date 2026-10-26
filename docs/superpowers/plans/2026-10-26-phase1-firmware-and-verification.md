# Phase 1: Software Firmware Environment & Verification Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a modular C/Assembly firmware build environment for PicoRV32, enable dynamic hex loading in the testbench, provide a unified top-level Makefile, and clean repository hygiene while ensuring 100% CI compatibility.

**Architecture:** 
A dedicated `sw/` directory hosts RISC-V C source code, bare-metal startup assembly (`crt0.s`), and a linker script (`sections.lds`) targeting the 64KB memory map. A cross-platform Python converter (`make_hex.py`) and a GNU Makefile generate 32-bit word-aligned `.hex` files. The Verilog testbench [`tb/picorv32_tb.v`](file:///c:/Users/Dung/vn-ntd-update/riscv_picorv32_sky130_asic_flow/tb/picorv32_tb.v) is updated with dynamic `$readmemh` loading and a fallback to the existing built-in sequence. A top-level [`Makefile`](file:///c:/Users/Dung/vn-ntd-update/riscv_picorv32_sky130_asic_flow/Makefile) standardizes simulation, firmware compilation, and EDA flow execution.

**Tech Stack:** RISC-V RV32I bare-metal C, GNU toolchain (`riscv-none-elf-gcc` / `riscv64-unknown-elf-gcc`), Python 3, Icarus Verilog (`iverilog`), Verilog-2001, Make.

**Spec:** Roadmapped in initial audit discussion (Phase 1: Verification & Software Environment).

## Global Constraints
- Target architecture: RISC-V RV32I (no standard M/A/F/D extensions).
- Base memory address: `0x00000000`, size 64 KB (`0x10000`).
- Testbench completion/status register address: `0x10000000` (`1` = SUCCESS, `2` = FAIL).
- Backward compatibility: If no external hex file is provided or found, testbench must run the built-in self-checking sequence without failing.
- Cross-platform: The firmware pipeline must allow simulation even on machines without a RISC-V GCC toolchain (via pre-compiled `.hex` and Python helper).

## Review Focus
1. Memory alignment: 32-bit word address conversion (`mem_addr >> 2`) in Verilog bus versus byte addresses in C pointers.
2. Stack pointer initialization: Stack must grow downwards from top of 64KB (`0x00010000`) without colliding with text/data sections.
3. Status write: Ensure `main.c` writes `1` to `*(volatile uint32_t *)0x10000000` upon success.
4. CI non-regression: `verify_metrics.yml` and existing `tb/run_sim.sh rtl` must pass with zero errors.
5. Large file management: Clarify and document `config.tcl` duplication.

---

### Task 1: Firmware Build Environment (`sw/`)

**Files:**
- Create: `sw/sections.lds`
- Create: `sw/crt0.s`
- Create: `sw/main.c`
- Create: `sw/make_hex.py`
- Create: `sw/Makefile`
- Create: `sw/firmware.hex`

**Interfaces:**
- Produces: `sw/firmware.hex` (text file with 32-bit hex words read by `$readmemh`).
- Writes to `0x10000000`: `0x00000001` on completion.

- [ ] **Step 1: Create `sw/sections.lds`**
Define memory layout for 64 KB RAM at `0x00000000`:
`.text` -> `.rodata` -> `.data` -> `.bss`. Define `_stack_top = 0x00010000`.

- [ ] **Step 2: Create `sw/crt0.s`**
Initialize stack pointer `sp`, clear `.bss` section, jump to `main`. After `main` returns, write `main` return value (or `1`) to address `0x10000000`, and enter a low-power infinite loop (`wfi` or `j .`).

- [ ] **Step 3: Create `sw/main.c`**
Implement functional verification functions in bare-metal C:
- `test_arithmetic()`: Addition, subtraction, multiplication emulation, bitwise AND/OR/XOR.
- `test_memory()`: Array read/write and memory integrity check.
- `test_loop()`: Fibonacci or summation loop ($\sum_{i=1}^{10} i = 55$).
Write `1` to `*(volatile uint32_t *)0x10000000` on passing.

- [ ] **Step 4: Create `sw/make_hex.py`**
A standalone Python script that:
- Converts a binary file (output from `objcopy -O binary`) to a 32-bit little-endian hex format suitable for `$readmemh`.
- Alternatively, generates a self-contained fallback `firmware.hex` directly encoding the test instructions if GCC is not installed on the host.

- [ ] **Step 5: Create `sw/Makefile`**
Include targets `all`, `clean`, `compile` using `riscv-none-elf-gcc` (or `riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O2 -nostdlib -Wl,-Bstatic,-T,sections.lds,--strip-debug`).

- [ ] **Step 6: Generate `sw/firmware.hex` and verify hex format**
Run `sw/make_hex.py` to ensure `sw/firmware.hex` is created, valid, and contains 32-bit hex words.

---

### Task 2: Testbench Enhancement (`tb/picorv32_tb.v` & `tb/run_sim.sh`)

**Files:**
- Modify: `tb/picorv32_tb.v`
- Modify: `tb/run_sim.sh`

**Interfaces:**
- Consumes: `sw/firmware.hex` or plusarg `+firmware=<path>`
- Outputs: VCD waveform when `+vcd` is provided, terminal log with pass/fail.

- [ ] **Step 1: Update `tb/picorv32_tb.v` for dynamic hex loading**
- Add string register `firmware_file`.
- Check `$value$plusargs("firmware=%s", firmware_file)`. If not provided, check if `"sw/firmware.hex"` can be opened.
- If hex file exists, load via `$readmemh(firmware_file, memory);`.
- If no file is found, retain the built-in 42-word verification sequence as a zero-dependency fallback.
- Support `$value$plusargs("vcd=%s", ...)` or `+vcd` to dump VCD waveforms for debugging.

- [ ] **Step 2: Update `tb/run_sim.sh`**
- Support extra arguments passed to the simulator (e.g., `./tb/run_sim.sh rtl +firmware=sw/firmware.hex`).
- In Docker mode, mount the repo and pass parameters properly.

- [ ] **Step 3: Run RTL simulation with hex file to verify pass**
Run simulation using Python/iverilog and confirm `[SIMULATION SUCCESS]`.

---

### Task 3: Unified Top-Level Makefile

**Files:**
- Create: `Makefile`

**Interfaces:**
- Provides standard developer entry points:
  - `make firmware`: Compiles C code in `sw/`
  - `make sim-rtl`: Runs RTL simulation
  - `make sim-gls`: Runs post-PnR Gate-Level simulation
  - `make view-layout`: Opens KLayout or runs export script
  - `make flow`: Runs OpenLane physical flow wrapper
  - `make clean`: Cleans build and simulation artifacts

- [ ] **Step 1: Write `Makefile` with cross-platform tool detection**
Provide recipes with clean messages, checking tool presence before running and showing friendly help instructions.

- [ ] **Step 2: Verify `make sim-rtl` and `make help`**
Test execution of Makefile targets.

---

### Task 4: Repository Hygiene & CI Verification

**Files:**
- Modify: `config.tcl` (add reference notice to `config/config.tcl`)
- Modify: `README.md` (add documentation for `sw/` and `Makefile`)
- Test: `.github/workflows/verify_metrics.yml`

- [ ] **Step 1: Clarify root `config.tcl`**
Add explicit comment that `config.tcl` is maintained for compatibility with direct root-mount flows and references `config/config.tcl`.

- [ ] **Step 2: Update `README.md`**
Document the new `sw/` firmware environment, the new top-level `Makefile` commands, and how to write/simulate custom C programs.

- [ ] **Step 3: Run local simulation and verify CI workflow integrity**
Execute verification to ensure CI workflow syntax and commands are completely unhampered.
