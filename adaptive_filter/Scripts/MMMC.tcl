###Project name: "Adaptive filter"
###Author: 		  Kavruk A.
###Technology:    X-FAB 180nm CMOS, XT018
###Library: 	 "D_CELLS_HD, 1.8V"
###Tools: 		 "Cadence Encounter 14.28"

###Stage: Place_and_Route
###FIle description: TCL script for Place and Route in multy-mode multy-corner
###Work Directory: /adaptive_filter/Scripts/ 

create_constraint_mode -name CONSTRAINTS -sdc_files {../Source/rtl/Top_syn_out.sdc}

create_library_set -name SLOWlib \
-timing {/Cadence/Libs/X_FAB/XKIT/xt018/diglibs/D_CELLS_HD/v4_0/liberty_LP5MOS/v4_0_0/PVT_1_80V_range/D_CELLS_HD_LP5MOS_slow_1_62V_175C.lib
}

create_library_set -name TYPlib \
-timing {/Cadence/Libs/X_FAB/XKIT/xt018/diglibs/D_CELLS_HD/v4_0/liberty_LP5MOS/v4_0_0/PVT_1_80V_range/D_CELLS_HD_LP5MOS_typ_1_80V_25C.lib
}

create_library_set -name FASTlib \
-timing {/Cadence/Libs/X_FAB/XKIT/xt018/diglibs/D_CELLS_HD/v4_0/liberty_LP5MOS/v4_0_0/PVT_1_80V_range/D_CELLS_HD_LP5MOS_fast_1_98V_m40C.lib
}

##create_op_cond -name PVT_slow_3_00V_175C \
##-library_file {<Path-to-cells-library>/liberty/.../<PVT corner name>/<Library
##name>_<Slow corner name>.lib} \
##-P {1} -V {3} -T {175}

create_rc_corner -name RCcornerMIN \
-cap_table /Cadence/Libs/X_FAB/XKIT/xt018/cadence/v7_0/capTbl/v7_0_1/xt018_xx43_MET4_METMID_METTHK_min.capTbl \
-qx_tech_file /Cadence/Libs/X_FAB/XKIT/xt018/cadence/v7_0/QRC_pvs/v7_0_3/XT018_1243/QRC-Min/qrcTechFile

create_rc_corner -name RCcornerTYP \
-cap_table /Cadence/Libs/X_FAB/XKIT/xt018/cadence/v7_0/capTbl/v7_0_1/xt018_xx43_MET4_METMID_METTHK_typ.capTbl \
-qx_tech_file /Cadence/Libs/X_FAB/XKIT/xt018/cadence/v7_0/QRC_pvs/v7_0_3/XT018_1243/QRC-Typ/qrcTechFile

create_rc_corner -name RCcornerMAX \
-cap_table /Cadence/Libs/X_FAB/XKIT/xt018/cadence/v7_0/capTbl/v7_0_1/xt018_xx43_MET4_METMID_METTHK_max.capTbl \
-qx_tech_file /Cadence/Libs/X_FAB/XKIT/xt018/cadence/v7_0/QRC_pvs/v7_0_3/XT018_1243/QRC-Max/qrcTechFile

create_delay_corner -name DELAYcornerSLOW \
-library_set SLOWlib \
-rc_corner RCcornerMAX

create_delay_corner -name DELAYcornerTYP \
-library_set TYPlib \
-rc_corner RCcornerTYP

create_delay_corner -name DELAYcornerFAST \
-library_set FASTlib \
-rc_corner RCcornerMIN

create_analysis_view -name MAXview \
-delay_corner {DELAYcornerSLOW} \
-constraint_mode {CONSTRAINTS}

create_analysis_view -name TYPview \
-delay_corner {DELAYcornerTYP} \
-constraint_mode {CONSTRAINTS}

create_analysis_view -name MINview \
-delay_corner {DELAYcornerFAST} \
-constraint_mode {CONSTRAINTS}

set_analysis_view -setup {MAXview} -hold {MINview}
