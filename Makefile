# ==============================================================================
# RISC-V PicoRV32 ASIC Flow & Verification Master Makefile
# Technology: SkyWater 130nm (sky130_fd_sc_hd)
# ==============================================================================

SHELL       := /bin/bash
PYTHON      ?= python3
REPO_ROOT   := $(shell pwd)

.PHONY: all help firmware sim-rtl sim-gls flow view-layout sta-mcmm irdrop sdf clean

# Default Target
all: help

help:
	@echo "======================================================================"
	@echo " PicoRV32 SkyWater 130nm ASIC Flow & Verification"
	@echo "======================================================================"
	@echo " Available Commands:"
	@echo "   make firmware     - Compile C/Assembly firmware into sw/firmware.hex"
	@echo "   make sim-rtl      - Run Behavioral RTL simulation"
	@echo "   make sim-gls      - Run Post-PnR Gate-Level simulation (GLS)"
	@echo "   make flow         - Execute complete OpenLane RTL-to-GDSII flow"
	@echo "   make sta-mcmm     - Run Multi-Corner STA (PVT: ss, tt, ff)"
	@echo "   make irdrop       - Run Power Grid Static IR-Drop Analysis"
	@echo "   make sdf          - Export Standard Delay Format (results/picorv32.sdf)"
	@echo "   make view-layout  - Render layout image (docs/images/layout.png)"
	@echo "   make clean        - Clean simulation, waveform and build artifacts"
	@echo "======================================================================"

firmware:
	@echo "[INFO] Building bare-metal firmware in sw/..."
	$(MAKE) -C sw all

sim-rtl: firmware
	@echo "[INFO] Launching RTL simulation..."
	./tb/run_sim.sh rtl

sim-gls: firmware
	@echo "[INFO] Launching Gate-Level Simulation (GLS)..."
	./tb/run_sim.sh gls

sta-mcmm:
	@echo "[INFO] Running Multi-Corner Static Timing Analysis (OpenSTA)..."
	./scripts/run_sta_mcmm.sh

irdrop:
	@echo "[INFO] Running Power Grid Static IR-Drop Analysis (OpenROAD)..."
	./scripts/run_irdrop.sh

sdf: sta-mcmm

flow:
	@echo "[INFO] Launching OpenLane physical implementation..."
	./scripts/run_flow.sh run_reproduce -overwrite

view-layout:
	@echo "[INFO] Exporting physical floorplan / layout image..."
	$(PYTHON) scripts/export_layout_image.py

clean:
	@echo "[INFO] Cleaning temporary simulation artifacts..."
	rm -f tb/simv tb/*.vcd tb/*.log sim.log
	$(MAKE) -C sw clean
