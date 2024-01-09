###Project name: "Adaptive filter"
###Author: 		  Kavruk A.
###Technology:    X-FAB 180nm CMOS, XT018
###Library: 	 "D_CELLS_HD, 1.8V"
###Tools: 		 "RTL Compiler"

###Stage: Synthesis
###FIle description: TCL script for Synthesis with fast corner
###Work Directory: /adaptive_filter/Scripts/ 
###Run command: RTL_Compiler ../Scripts/synth.tcl

## Setup technology files
include ../Scripts/fab_slow.tcl

## Read in Verilog HDL files
read_hdl -sv ../Source/rtl/adaptive_filter_pkg.sv
read_hdl -sv ../Source/rtl/adaptive_filter.sv

## Compile our code (create a technology-independent schematic)
elaborate

## Setup design constraints
read_sdc ../Source/rtl/adaptive_filter_constr.sdc

## Synthesize our schematic (create a technology-dependent schematic)
synthesize -to_mapped

## Write out area and timing reports
report timing > ../Reports/Synthesis/timing_report
report area > ../Reports/Synthesis/area_report

## Write out synthesized Verilog netlist
write_hdl -mapped > ../Outputs/Synthesis/synth_hdl.v

## Write out the SDC file we will take into the place n route tool
write_sdc > ../Source/rtl/Top_syn_out.sdc

gui_show
