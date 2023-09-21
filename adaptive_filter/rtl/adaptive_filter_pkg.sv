package adaptive_filter_pkg;

	localparam DATA_WIDTH = 14;
	
	localparam FIR_DIFF_ORDER 	  = 9;
	localparam FIR_DIFF_COEFF_NUM = (FIR_DIFF_ORDER + 1) >> 1;

	localparam int DIFF_COEFF_WL [FIR_DIFF_COEFF_NUM-1:0] = {8, 9, 9, 6, 7};
	localparam int DIFF_COEFF_FL [FIR_DIFF_COEFF_NUM-1:0] = {6, 7, 7, 4, 5  };

	localparam INTEGR_COEFF_NUM    = 2;
	localparam int INTEGR_COEFF_WL = 1;
	localparam int INTEGR_COEFF_FL [INTEGR_COEFF_NUM-1:0] = {6, 5}; 

	logic [DIFF_COEFF_WL[0]-DIFF_COEFF_FL[0]-1:-DIFF_COEFF_FL[0]] fir_diff_coeff_a0 = 8'hFF;
	logic [DIFF_COEFF_WL[1]-DIFF_COEFF_FL[1]-1:-DIFF_COEFF_FL[1]] fir_diff_coeff_a1 = 8'h19;
	logic [DIFF_COEFF_WL[2]-DIFF_COEFF_FL[2]-1:-DIFF_COEFF_FL[2]] fir_diff_coeff_a2 = 8'hCD;
	logic [DIFF_COEFF_WL[3]-DIFF_COEFF_FL[3]-1:-DIFF_COEFF_FL[3]] fir_diff_coeff_a3 = 8'h07;
	logic [DIFF_COEFF_WL[4]-DIFF_COEFF_FL[4]-1:-DIFF_COEFF_FL[4]] fir_diff_coeff_a4 = 8'h13;

	logic [INTEGR_COEFF_WL[0]-INTEGR_COEFF_FL[0]-1:-INTEGR_COEFF_FL[0]] fir_integr_coeff_a0 = 8'h17;
	logic [INTEGR_COEFF_WL[1]-INTEGR_COEFF_FL[1]-1:-INTEGR_COEFF_FL[1]] fir_integr_coeff_a1 = 8'h29;
	
	localparam int MULTYPLYERS_WL [FIR_DIFF_COEFF_NUM-1:0] = {18, 19, 20, 14, 14};
	localparam int MULTYPLYERS_FL [FIR_DIFF_COEFF_NUM-1:0] = {12, 11, 12, 6, 6  };

	localparam OP_SUMM_WL = 20;
	localparam OP_SUMM_FL = 12;

	localparam OP_DIFF_WL = 15;
	localparam OP_DIFF_FL = 6;

endpackage : adaptive_filter_pkg