# SDC Constraints for RISC-V PicoRV32 Core
set clock_period $::env(CLOCK_PERIOD)
create_clock -name clk -period $clock_period [get_ports clk]

# Clock Uncertainty & Transition
set_clock_uncertainty 0.25 [get_clocks clk]
set_clock_transition 0.15 [get_clocks clk]

# I/O Delays
set in_delay [expr $clock_period * 0.20]
set out_delay [expr $clock_period * 0.20]

set all_inputs_no_clk [remove_from_collection [all_inputs] [get_ports clk]]

set_input_delay $in_delay -clock [get_clocks clk] $all_inputs_no_clk
set_output_delay $out_delay -clock [get_clocks clk] [all_outputs]

# Driving cell and output capacitance load
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 $all_inputs_no_clk
set_load 0.035 [all_outputs]
