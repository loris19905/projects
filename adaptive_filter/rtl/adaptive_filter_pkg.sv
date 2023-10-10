package adaptive_filter_pkg;

	localparam WORDLENGTH 		 = 14;
	localparam INT32_SIZE 		 = 32;
	localparam FRACTIONAL_LENGTH = 6;
	
	localparam FIR_DIFF_ORDER 	  = 9;
	localparam FIR_DIFF_COEFF_NUM = (FIR_DIFF_ORDER + 1) >> 1;

	localparam [FIR_DIFF_COEFF_NUM-1:0][INT32_SIZE-1:0] DIFF_COEFF_WL = {7, 6, 9, 9, 8};
	localparam [FIR_DIFF_COEFF_NUM-1:0][INT32_SIZE-1:0] DIFF_COEFF_FL = {5, 4, 7, 7, 6};

	localparam INTEGR_COEFF_NUM    						  			  = 2;
	localparam [INTEGR_COEFF_NUM-1:0][INT32_SIZE-1:0] INTEGR_COEFF_WL = {6, 7};
	localparam [INTEGR_COEFF_NUM-1:0][INT32_SIZE-1:0] INTEGR_COEFF_FL = {5, 6}; 

	logic [DIFF_COEFF_WL[0]-DIFF_COEFF_FL[0]-1:-DIFF_COEFF_FL[0]] fir_diff_coeff_a0 = 8'hFF;
	logic [DIFF_COEFF_WL[1]-DIFF_COEFF_FL[1]-1:-DIFF_COEFF_FL[1]] fir_diff_coeff_a1 = 9'h019;
	logic [DIFF_COEFF_WL[2]-DIFF_COEFF_FL[2]-1:-DIFF_COEFF_FL[2]] fir_diff_coeff_a2 = 9'h1CD;
	logic [DIFF_COEFF_WL[3]-DIFF_COEFF_FL[3]-1:-DIFF_COEFF_FL[3]] fir_diff_coeff_a3 = 6'h07;
	logic [DIFF_COEFF_WL[4]-DIFF_COEFF_FL[4]-1:-DIFF_COEFF_FL[4]] fir_diff_coeff_a4 = 7'h13;

	logic [INTEGR_COEFF_WL[0]-INTEGR_COEFF_FL[0]-1:-INTEGR_COEFF_FL[0]] fir_integr_coeff_a0 = 7'h17;
	logic [INTEGR_COEFF_WL[1]-INTEGR_COEFF_FL[1]-1:-INTEGR_COEFF_FL[1]] fir_integr_coeff_a1 = 6'h29;
	
	localparam [FIR_DIFF_COEFF_NUM-1:0][INT32_SIZE-1:0] MULTYPLYERS_WL = {14, 14, 20, 19, 18};
	localparam [FIR_DIFF_COEFF_NUM-1:0][INT32_SIZE-1:0] MULTYPLYERS_FL = {6 , 6 , 12, 11, 12};

	localparam OP_SUMM_WL = 20;
	localparam OP_SUMM_FL = 12;

	localparam OP_DIFF_WL = 15;
	localparam OP_DIFF_FL = 6;

endpackage : adaptive_filter_pkg