# ==============================================================================
# OpenROAD Static IR-Drop & Power Grid Integrity Analysis
# Process: SkyWater 130nm (sky130_fd_sc_hd)
# Design:  RISC-V PicoRV32 Core
# ==============================================================================

set DESIGN_NAME "picorv32"
set DEF_FILE    "results/picorv32.def"
set SPEF_FILE   "results/picorv32.spef"
set SDC_FILE    "results/picorv32.sdc"

# Discover PDK Root
if {[info exists env(PDK_ROOT)] && [file exists "$env(PDK_ROOT)/sky130A"]} {
    set PDK_ROOT $env(PDK_ROOT)
} elseif {[file exists "/openlane/pdks/sky130A"]} {
    set PDK_ROOT "/openlane/pdks"
} elseif {[file exists "$env(HOME)/.volare/sky130A"]} {
    set PDK_ROOT "$env(HOME)/.volare"
} elseif {[file exists "$env(HOME)/.ciel/sky130A"]} {
    set PDK_ROOT "$env(HOME)/.ciel"
} else {
    set PDK_ROOT "/openlane/pdks"
}

set TECH_LEF "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
set CELL_LEF "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set LIB_FILE "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

puts "========================================================================"
puts " Starting Power Grid Integrity Analysis for Design: $DESIGN_NAME"
puts " PDK Root: $PDK_ROOT"
puts "========================================================================"

file mkdir "reports"

# 1. Read LEFs & DEF
read_lef $TECH_LEF
read_lef $CELL_LEF
read_def $DEF_FILE

# 2. Read Timing Library & Constraints
read_liberty $LIB_FILE
read_sdc $SDC_FILE

# 3. Read Parasitics
if {[file exists $SPEF_FILE]} {
    read_spef $SPEF_FILE
}

# 4. Set Default Switching Activity
set_power_activity -input -activity 0.1

# 5. Analyze Power Grid for VPWR (1.80 V)
puts "\n------------------------------------------------------------------------"
puts " Analyzing Power Grid IR-Drop on Power Rail: VPWR (1.80V)"
puts "------------------------------------------------------------------------"
analyze_power_grid -net VPWR -outfile "reports/irdrop_vpwr.rpt"

# 6. Analyze Ground Bounce for VGND (0.00 V)
puts "\n------------------------------------------------------------------------"
puts " Analyzing Ground Bounce on Ground Rail: VGND (0.00V)"
puts "------------------------------------------------------------------------"
analyze_power_grid -net VGND -outfile "reports/irdrop_vgnd.rpt"

puts "\n========================================================================"
puts " Power Grid IR-Drop Analysis Complete. Reports saved to reports/irdrop_*"
puts "========================================================================"
