###Project name: "Adaptive filter"
###Author: 		  Kavruk A.
###Technology:    X-FAB 180nm CMOS, XT018
###Library: 	 "D_CELLS_HD, 1.8V"
###Tools: 		 "Cadence Encounter 14.28", "RTL Compiler"

###Stage: Synthesis, Place_and_Route
###File description: Timing constraints
###Work Directory: /adaptive_filter/Source/rtl/

create_clock -name clk -period 50 [get_ports clk]

set_input_delay  	-clock clk -max 0.5 [get_ports  -filter {@port_direction == in}]
set_output_delay 	  -clock clk -max 0.5 [get_ports  -filter {@port_direction == out}]

set_clock_uncertainty -from [get_clocks {clk}] 0.01

set_load 			  -pin_load 0.001 [get_ports {m*}]s