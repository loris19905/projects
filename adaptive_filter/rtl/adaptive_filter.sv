`timescale 1ns / 1ns

  /*
  * Title        : Адаптивный фильтр (дифференциатор, интегратор)
  * File         : adaptive_filter.sv
  * Description  : Реализация адаптивного фильтра: по ctrl = 1 фильтр работает в режиме интегратора, ctrl = 0 - в режиме дифференциатор.
  */

module adaptive_filter 
    import adaptive_filter_pkg::*;
(	
    input  logic        clk,
    input  logic        srst,
    input  logic        ctrl,

    input  logic [7:-6] s_tdata,
    input  logic        s_tvalid,

    output logic [7:-6] m_tdata,
    output logic        m_tvalid
);

    localparam REG_ZERO_START_ADDR = 6;
    localparam DELAY_FEEDBACK_LOOP = 2;

    logic [FIR_DIFF_ORDER-1:0     ][DATA_WIDTH-FRACTIONAL_LENGTH-1:-FRACTIONAL_LENGTH] s_tdata_d;
    logic [DELAY_FEEDBACK_LOOP-1:0][OP_SUMM_WL-OP_SUMM_FL-1:-OP_SUMM_FL]              loop_tdata;
    logic s_tvalid_d;

    always_ff @(posedge clk) begin
        if (srst) begin
            s_tdata_d  <= '0;
            loop_tdata <= '0;
            m_tdata    <= '0;
            s_tvalid_d <= '0;
            m_tvalid   <= '0;  
        end else begin
            for (int i = 0; i < FIR_DIFF_ORDER; i++) begin
                if (i == 0) begin
                    s_tdata_d[i] <= (s_tvalid) ? s_tdata : s_tdata_d[i];
                end else begin
                    if (ctrl) begin
                        if (s_tvalid) begin
                            s_tdata_d[i] <= (i >= REG_ZERO_START_ADDR) ? '0 : s_tdata_d[i-1];
                        end else begin    
                            s_tdata_d[i] <= s_tdata_d[i];
                        end
                    end else begin
                        s_tdata_d[i] <= (s_tvalid) ? s_tdata_d[i-1] : s_tdata_d[i];
                    end
                end
            end

            if (s_tvalid) begin
                loop_tdata[0] <= summ_res[FIR_DIFF_COEFF_NUM-1];
                m_tdata       <= summ_res[4][7:-6]; 
            end else begin
                loop_tdata[0] <= loop_tdata[0];
                m_tdata       <= m_tdata;
            end

            if (s_tvalid_d) begin
                loop_tdata[DELAY_FEEDBACK_LOOP-1] <= (ctrl) ? loop_tdata[0] : '0;
            end else begin
                loop_tdata[DELAY_FEEDBACK_LOOP-1] <= loop_tdata[DELAY_FEEDBACK_LOOP-1];
            end

            m_tvalid   <= s_tvalid;
            s_tvalid_d <= s_tvalid;
        end  
    end

    logic [FIR_DIFF_COEFF_NUM-1:0][OP_DIFF_WL-OP_DIFF_FL-1:-OP_DIFF_FL] diff_res;
    logic [FIR_DIFF_COEFF_NUM-1:0][OP_SUMM_WL-OP_SUMM_FL-1:-OP_SUMM_FL] summ_res;
    
    logic [MULTYPLYERS_WL[0]-MULTYPLYERS_FL[0]-1:-MULTYPLYERS_FL[0]] mult_res_0;
    logic [MULTYPLYERS_WL[1]-MULTYPLYERS_FL[1]-1:-MULTYPLYERS_FL[1]] mult_res_1;
    logic [MULTYPLYERS_WL[2]-MULTYPLYERS_FL[2]-1:-MULTYPLYERS_FL[2]] mult_res_2;
    logic [MULTYPLYERS_WL[3]-MULTYPLYERS_FL[3]-1:-MULTYPLYERS_FL[3]] mult_res_3;
    logic [MULTYPLYERS_WL[4]-MULTYPLYERS_FL[4]-1:-MULTYPLYERS_FL[4]] mult_res_4;

    /*
    logic op1_is_neg;
    logic op2_is_neg;
    logic is_op1_more_than_op2; //по модулю
    logic [DATA_WIDTH-FRACTIONAL_LENGTH-1:-FRACTIONAL_LENGTH] diff_res_tmp;
    */

    always_comb begin
        if (srst) begin
            mult_res_0 = '0;
            mult_res_1 = '0;
            mult_res_2 = '0;
            mult_res_3 = '0;
            mult_res_4 = '0;
            summ_res   = '0;   
        end else begin
            for (int i = 0; i < FIR_DIFF_COEFF_NUM; i++) begin
                if (i == 0) begin

                    /*
                    op1_is_neg           = s_tdata[DATA_WIDTH-FRACTIONAL_LENGTH-1];
                    op2_is_neg           = s_tdata_d[FIR_DIFF_ORDER-1][DATA_WIDTH-FRACTIONAL_LENGTH-1];
                    is_op1_more_than_op2 = s_tdata[DATA_WIDTH-FRACTIONAL_LENGTH-2:-FRACTIONAL_LENGTH] >= s_tdata_d[FIR_DIFF_ORDER-1][DATA_WIDTH-FRACTIONAL_LENGTH-2:-FRACTIONAL_LENGTH];
                    diff_res_tmp         = s_tdata - s_tdata_d[FIR_DIFF_ORDER-1];
                    */
                    diff_res[i] = $signed(s_tdata) - $signed(s_tdata_d[FIR_DIFF_ORDER-1]);
                    /*
                    if (op1_is_neg && op2_is_neg) begin
                        diff_res[i] = (is_op1_more_than_op2) ? {1'b1, diff_res_tmp} : {1'b0, diff_res_tmp};
                    end else if (~op1_is_neg && op2s_is_neg) begin
                        diff_res[i] = {1'b0, diff_res_tmp};
                    end else if (op1_is_neg && ~op2_is_neg) begin
                        diff_res[i] = {1'b1, diff_res_tmp};
                    end else begin
                        diff_res[i] = (is_op1_more_than_op2) ? {1'b0, diff_res_tmp} : {1'b1, diff_res_tmp};
                    end
                    */
                end else begin
                    diff_res[i] = $signed(s_tdata_d[i-1]) - $signed(s_tdata_d[FIR_DIFF_ORDER-i-1]);
                    /*
                    op1_is_neg           = s_tdata_d[i-1][DATA_WIDTH-FRACTIONAL_LENGTH-1];
                    op2_is_neg           = s_tdata_d[FIR_DIFF_ORDER-1][DATA_WIDTH-FRACTIONAL_LENGTH-1];
                    is_op1_more_than_op2 = s_tdata_d[i-1][DATA_WIDTH-FRACTIONAL_LENGTH-2:-FRACTIONAL_LENGTH] >= s_tdata_d[FIR_DIFF_ORDER-i-1][DATA_WIDTH-FRACTIONAL_LENGTH-2:-FRACTIONAL_LENGTH];
                    diff_res_tmp         = s_tdata_d[i-1] - s_tdata_d[FIR_DIFF_ORDER-1];

                    if (op1_is_neg && op2_is_neg) begin
                        diff_res[i] = (is_op1_more_than_op2) ? {1'b1, diff_res_tmp} : {1'b0, diff_res_tmp};
                    end else if (~op1_is_neg && op2_is_neg) begin
                        diff_res[i] = {1'b0, diff_res_tmp};
                    end else if (op1_is_neg && ~op2_is_neg) begin
                        diff_res[i] = {1'b1, diff_res_tmp};
                    end else begin
                        diff_res[i] = (is_op1_more_than_op2) ? {1'b0, diff_res_tmp} : {1'b1, diff_res_tmp};
                    end
                    */
                end
            end
            
            if (ctrl) begin

                mult_res_0  = $signed({1'b0, fir_integr_coeff_a0}) * $signed(diff_res[0]);
                mult_res_1  = $signed({1'b0, fir_integr_coeff_a1}) * $signed(diff_res[1]);
                mult_res_2  = $signed({1'b0, fir_integr_coeff_a0}) * $signed(diff_res[2]);
                mult_res_3  = '0;
                mult_res_4  = '0;
                summ_res[0] = $signed(mult_res_0 ) + $signed(mult_res_1);
                summ_res[1] = $signed(summ_res[0]) + $signed(mult_res_2);
                summ_res[2] = $signed(summ_res[1]) + $signed(mult_res_3);
                summ_res[3] = $signed(summ_res[2]) + $signed(mult_res_4);
                summ_res[4] = $signed(summ_res[3]) + $signed(loop_tdata[DELAY_FEEDBACK_LOOP-1]);
            
            end else begin

                mult_res_0  = fir_diff_coeff_a0 * diff_res[0];
                mult_res_1  = fir_diff_coeff_a1 * diff_res[1];
                mult_res_2  = fir_diff_coeff_a2 * diff_res[2];
                mult_res_3  = fir_diff_coeff_a3 * diff_res[3];
                mult_res_4  = fir_diff_coeff_a4 * diff_res[4];
                summ_res[0] = $signed(mult_res_0 ) + $signed(mult_res_1);
                summ_res[1] = $signed(summ_res[0]) + $signed(mult_res_2);
                summ_res[2] = $signed(summ_res[1]) + $signed(mult_res_3);
                summ_res[3] = $signed(summ_res[2]) + $signed(mult_res_4);
                summ_res[4] = summ_res[3];
            
            end   
        end
        
    end
endmodule
