###Project name: "Adaptive filter"
###Author: 		  Kavruk A.
###Technology:    X-FAB 180nm CMOS, XT018
###Library: 	 "D_CELLS_HD, 1.8V"
###Tools: 		 "RTL Compiler"

###Stage: Synthesis
###FIle description: SDC-file for Synthesis
###Work Directory: /adaptive_filter/Source/rtl/ 

set_units -time ns -capacitance pF

create_clock -name clk -period 25 [get_ports clk]

set_input_delay  	-clock clk -max 0.5 [get_ports  -filter {@port_direction == in}]
set_output_delay 	-clock clk -max 0.5 [get_ports  -filter {@port_direction == out}]

set_clock_uncertainty   -to clk 0.25

set_load 		0.5 [all_outputs]
