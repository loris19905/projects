create_clock -name clk -period 50 [get_ports clk]

set_input_delay  0.5 -clock [get_ports clk] [get_ports  -filter {@port_direction == in}]
set_output_delay 0.5 -clock [get_ports clk] [get_ports  -filter {@port_direction == out}]