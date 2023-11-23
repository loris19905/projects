//Project name: "Adaptive filter"
//Author: 		 Kavruk A.
//File description: Package for RTL parameters

package adaptive_filter_pkg;

	localparam WORDLENGTH 		 = 14;
	localparam FRACTIONAL_LENGTH = 6;
	
	localparam FIR_DIFF_ORDER 	  = 9;
	localparam FIR_DIFF_COEFF_NUM = (FIR_DIFF_ORDER + 1) >> 1;

	parameter  int DIFF_COEFF_WL [FIR_DIFF_COEFF_NUM-1:0] = '{7, 6, 9, 9, 8};
	parameter  int DIFF_COEFF_FL [FIR_DIFF_COEFF_NUM-1:0] = '{5, 4, 7, 7, 6};

	localparam INTEGR_COEFF_NUM    						  = 2;
	parameter  int INTEGR_COEFF_WL [INTEGR_COEFF_NUM-1:0] = '{6, 7};
	parameter  int INTEGR_COEFF_FL [INTEGR_COEFF_NUM-1:0] = '{5, 6}; 
	
	parameter int MULTYPLYERS_WL [FIR_DIFF_COEFF_NUM-1:0] = '{14, 14, 20, 19, 18};
	parameter int MULTYPLYERS_FL [FIR_DIFF_COEFF_NUM-1:0] = '{6 , 6 , 12, 11, 12};

	localparam OP_SUMM_WL = 20;
	localparam OP_SUMM_FL = 12;

	localparam OP_DIFF_WL = 15;
	localparam OP_DIFF_FL = 6;

endpackage : adaptive_filter_pkg
