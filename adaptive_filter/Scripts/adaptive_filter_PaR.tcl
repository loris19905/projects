###Project name: "Adaptive filter"
###Author: 		  Kavruk A.
###Technology:    X-FAB 180nm CMOS, XT018
###Library: 	 "D_CELLS_HD, 1.8V"
###Tools: 		 "Cadence Encounter 14.28"
###Stage: Place_and_Route
###FIle description: TCL script for Place and Route
###Work Directory: /adaptive_filter/Scripts/
###Run command: Encounter ../Scripts/adaptive_filter_PaR.tcl


#Import design
set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
suppressMessage ENCEXT-2799
set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
suppressMessage ENCEXT-2799
win
set ::TimeLib::tsgMarkCellLatchConstructFlag 1
set defHierChar /
set distributed_client_message_echo 1
set gpsPrivate::dpgNewAddBufsDBUpdate 1
set gpsPrivate::lsgEnableNewDbApiInRestruct 1
set init_design_settop 0
set init_gnd_net VSS
set init_io_file ../Outputs/Place_and_Route/Module_pins
set init_lef_file {/Cadence/Libs/X_FAB/XKIT/xt018/cadence/v7_0/techLEF/v7_0_1_1/xt018_xx43_MET4_METMID_METTHK.lef 
/Cadence/Libs/X_FAB/XKIT/xt018/diglibs/D_CELLS_HD/v4_0/LEF/v4_0_0/xt018_D_CELLS_HD.lef}
set init_mmmc_file ../Scripts/MMMC.tcl
set init_oa_search_lib {}
set init_pwr_net VDD
set init_verilog ../Outputs/Synthesis/synth_hdl.v
set lsgOCPGainMult 1.000000
set pegDefaultResScaleFactor 1.000000
set pegDetailResScaleFactor 1.000000
set timing_library_float_precision_tol 0.000010
set timing_library_load_pin_cap_indices {}
set tso_post_client_restore_command {update_timing ; write_eco_opt_db ;}
init_design

#Floorplanning: chip geometry
getIoFlowFlag
setIoFlowFlag 0
floorPlan -fplanOrigin center -site core_hd -r 1 0.5 10 10 10 10
uiSetTool select
getIoFlowFlag
fit
globalNetConnect VDD -type pgpin -pin vdd -inst *
globalNetConnect VSS -type pgpin -pin gnd -inst *
globalNetConnect VDD -type tiehi -inst * -module {}
globalNetConnect VSS -type tielo -inst * -module {}


#Floorplanning: power rails
set sprCreateIeRingNets {}
set sprCreateIeRingLayers {}
set sprCreateIeRingWidth 1.0
set sprCreateIeRingSpacing 1.0
set sprCreateIeRingOffset 1.0
set sprCreateIeRingThreshold 1.0
set sprCreateIeRingJogDistance 1.0
addRing -skip_via_on_wire_shape Noshape -skip_via_on_pin Standardcell -stacked_via_top_layer METTPL -type core_rings -jog_distance 3.15 -threshold 3.15 -nets {VSS VDD} -follow core -stacked_via_bottom_layer MET1 -layer {bottom MET1 top MET1 right MET2 left MET2} -width 3 -spacing 2.5 -offset 3.15
set sprCreateIeStripeNets {}
set sprCreateIeStripeLayers {}
set sprCreateIeStripeWidth 10.0
set sprCreateIeStripeSpacing 2.0
set sprCreateIeStripeThreshold 1.0
addRing -skip_via_on_wire_shape Noshape -skip_via_on_pin Standardcell -stacked_via_top_layer METTPL -type core_rings -jog_distance 3.15 -threshold 3.15 -nets {VSS VDD} -follow core -stacked_via_bottom_layer MET1 -layer {bottom MET1 top MET1 right MET2 left MET2} -width 3 -spacing {bottom 0.23 top 0.23 right 0.28 left 0.28} -offset 3.15
win
set sprCreateIeRingNets {}
set sprCreateIeRingLayers {}
set sprCreateIeRingWidth 1.0
set sprCreateIeRingSpacing 1.0
set sprCreateIeRingOffset 1.0
set sprCreateIeRingThreshold 1.0
set sprCreateIeRingJogDistance 1.0
addRing -skip_via_on_wire_shape Noshape -skip_via_on_pin Standardcell -stacked_via_top_layer METTPL -type core_rings -jog_distance 3.15 -threshold 3.15 -nets {VSS VDD} -follow core -stacked_via_bottom_layer MET1 -layer {bottom MET1 top MET1 right MET2 left MET2} -width 3 -spacing 2.5 -offset 3.15
addRing -skip_via_on_wire_shape Noshape -skip_via_on_pin Standardcell -stacked_via_top_layer METTPL -type core_rings -jog_distance 3.15 -threshold 3.15 -nets {VSS VDD} -follow core -stacked_via_bottom_layer MET1 -layer {bottom MET1 top MET1 right MET2 left MET2} -width 3 -spacing {bottom 0.23 top 0.23 right 0.28 left 0.28} -offset 3.15
set sprCreateIeStripeNets {}
set sprCreateIeStripeLayers {}
set sprCreateIeStripeWidth 10.0
set sprCreateIeStripeSpacing 2.0
set sprCreateIeStripeThreshold 1.0
addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit MET3 -max_same_layer_jog_length 6 -padcore_ring_bottom_layer_limit MET1 -set_to_set_distance 25 -skip_via_on_pin Standardcell -stacked_via_top_layer METTPL -padcore_ring_top_layer_limit MET3 -spacing 2.5 -xleft_offset 30 -xright_offset 30 -merge_stripes_value 3.15 -layer MET2 -block_ring_bottom_layer_limit MET1 -width 3 -nets {VDD VSS} -stacked_via_bottom_layer MET1
sroute -connect { blockPin padPin padRing corePin floatingStripe } -layerChangeRange { MET1 METTPL } -blockPinTarget { nearestTarget } -padPinPortConnect { allPort oneGeom } -padPinTarget { nearestTarget } -corePinTarget { firstAfterRowEnd } -floatingStripeTarget { blockring padring ring stripe ringpin blockpin followpin } -allowJogging 1 -crossoverViaLayerRange { MET1 METTPL } -nets { VSS VDD } -allowLayerChange 1 -blockPin useLef -targetViaLayerRange { MET1 METTPL }
editPowerVia -skip_via_on_pin Standardcell -bottom_layer MET1 -add_vias 1 -top_layer METTPL
set sprEpvLayers {}
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null

#Placement
timeDesign -prePlace -idealClock -pathReports -drvReports -slackReports -numPaths 50 -prefix adaptive_filter_prePlace -outDir ../Reports/Place_and_Route
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -prePlace -idealClock -pathReports -drvReports -slackReports -numPaths 50 -prefix adaptive_filter_prePlace -outDir ../Reports/Place_and_Route
setPlaceMode -fp false
placeDesign -inPlaceOpt
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null

#CTS
timeDesign -preCTS -idealClock -pathReports -drvReports -slackReports -numPaths 50 -prefix adaptive_filter_preCTS -outDir ../Reports/Place_and_Route
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -preCTS -hold -idealClock -pathReports -slackReports -numPaths 50 -prefix adaptive_filter_preCTS -outDir ../Reports/Place_and_Route
setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -preCTS
createClockTreeSpec -bufferList {BUHDX0 BUHDX1 BUHDX12 BUHDX2 BUHDX3 BUHDX4 BUHDX6 BUHDX8 DLY1HDX0 DLY1HDX1 DLY2HDX0 DLY2HDX1 DLY4HDX0 DLY4HDX1 DLY8HDX0 DLY8HDX1 INHDX0 INHDX1 INHDX2 INHDX12 INHDX3 INHDX4 INHDX6 INHDX8 STEHDX0 STEHDX1 STEHDX2 STEHDX4} -file Clock.ctstch
clockDesign -specFile Clock.ctstch -outDir clock_report -fixedInstBeforeCTS
setCTSMode -engine ck
clockDesign -specFile Clock.ctstch -outDir clock_report -fixedInstBeforeCTS
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix adaptive_filter_postCTS -outDir ../Reports/Place_and_Route
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -preCTS -hold -idealClock -pathReports -slackReports -numPaths 50 -prefix adaptive_filter_preCTS -outDir ../Reports/Place_and_Route
setOptMode -fixCap false -fixTran false -fixFanoutLoad false
optDesign -postCTS -incr
optDesign -postCTS -hold -incr

#Routing
setNanoRouteMode -quiet -timingEngine {}
setNanoRouteMode -quiet -routeWithSiPostRouteFix 0
setNanoRouteMode -quiet -drouteStartIteration default
setNanoRouteMode -quiet -routeTopRoutingLayer default
setNanoRouteMode -quiet -routeBottomRoutingLayer default
setNanoRouteMode -quiet -drouteEndIteration default
setNanoRouteMode -quiet -routeWithTimingDriven false
setNanoRouteMode -quiet -routeWithSiDriven false
routeDesign -globalDetail
setAnalysisMode -analysisType onChipVariation -skew true -clockPropagation sdcControl
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postRoute -pathReports -drvReports -slackReports -numPaths 50 -prefix adaptive_filter_postRoute -outDir ../Reports/Place_and_Route
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postRoute -hold -pathReports -slackReports -numPaths 50 -prefix adaptive_filter_postRoute -outDir ../Reports/Place_and_Route
setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -postRoute
optDesign -postRoute -hold
getFillerMode -quiet
addFiller -cell FEED7HD FEED5HD FEED3HD FEED2HD FEED25HD FEED1HD FEED15HD FEED10HD -prefix FILLER

#Verification and parasitic extraction
setVerifyGeometryMode -area { 0 0 0 0 } -minWidth true -minSpacing true -minArea true -sameNet true -short true -overlap true -offRGrid false -offMGrid true -mergedMGridCheck true -minHole true -implantCheck true -minimumCut true -minStep true -viaEnclosure true -antenna false -insuffMetalOverlap true -pinInBlkg false -diffCellViol true -sameCellViol false -padFillerCellsOverlap true -routingBlkgPinOverlap true -routingCellBlkgOverlap true -regRoutingOnly false -stackedViasOnRegNet false -wireExt true -useNonDefaultSpacing false -maxWidth true -maxNonPrefLength -1 -error 1000
verifyGeometry
setVerifyGeometryMode -area { 0 0 0 0 }
verify_drc -report adaptive_filter.drc.rpt -limit 1000
verifyConnectivity -type all -error 1000 -warning 50
setExtractRCMode -engine postRoute -effortLevel signoff
extractRC
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -signoff -pathReports -drvReports -slackReports -numPaths 50 -prefix adaptive_filter_signOff -outDir ../Reports/Place_and_Route
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -signoff -hold -pathReports -slackReports -numPaths 50 -prefix adaptive_filter_signOff -outDir ../Reports/Place_and_Route
all_hold_analysis_views 
all_setup_analysis_views 

#SDF, DEF, logic and physical netlist
write_sdf -view MAXview ../Outputs/adaptive_filter.sdf
saveNetlist ../Outputs/adaptive_filter_logic
saveNetlist ../Outputs/asic_filter.v
global dbgLefDefOutVersion
set dbgLefDefOutVersion 5.8
defOut -floorplan -netlist -routing ../Outputs/adaptive_filter.def
set dbgLefDefOutVersion 5.8
