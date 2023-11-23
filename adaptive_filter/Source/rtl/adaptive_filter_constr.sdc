create_clock -name clk -period 50 [get_ports clk]

set_input_delay  	-clock clk -max 0.5 [get_ports  -filter {@port_direction == in}]
set_output_delay 	  -clock clk -max 0.5 [get_ports  -filter {@port_direction == out}]

set_clock_uncertainty -from [get_clocks {clk}] 0.01

set_load 			  -pin_load 0.001 [get_ports {m*}]s