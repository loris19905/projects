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

    input  logic [13:0] s_tdata,
    output logic [13:0] m_tdata
);
    localparam DATA_WIDTH          = 14;
    localparam REG_ZERO_START_ADDR = 6;
    localparam DELAY_FEEDBACK_LOOP = 2;
    localparam SIGNED_BIT          = 1;

    logic [FIR_DIFF_ORDER-1:0     ][DATA_WIDTH-1:0                               ] s_tdata_d;
    logic [DELAY_FEEDBACK_LOOP-1:0][OP_SUMM_WL-OP_SUMM_FL+SIGNED_BIT-1:OP_SUMM_FL] loop_tdata;

    always_ff @(posedge clk) begin
        if (srst) begin
            s_tdata_d  <= '0;
            loop_tdata <= '0;  
        end else begin
            for (int i = 0; i < FIR_DIFF_ORDER; i++) begin
                if (i == 0) begin
                    s_tdata_d[i] <= s_tdata;
                end else begin
                    if (ctrl) begin
                        s_tdata_d[i] <= (i >= REG_ZERO_START_ADDR) ? '0 : s_tdata_d[i-1];
                    end else begin
                        s_tdata_d[i] <= s_tdata_d[i-1];
                    end
                end
                s_tdata_d[i] <= (i == 0) ? s_tdata : s_tdata_d[i-1];
            end
            loop_tdata[0] <= summ_res[FIR_DIFF_COEFF_NUM-1];
            loop_tdata[1] <= (ctrl) ? loop_tdata[0] : '0;
        end  
    end

    logic [FIR_DIFF_ORDER-1:0    ][OP_DIFF_WL-OP_DIFF_FL-1:OP_DIFF_FL] diff_res;
    logic [FIR_DIFF_COEFF_NUM-1:0][OP_SUMM_WL-OP_SUMM_FL-1:OP_SUMM_FL] summ_res;
    
    logic [MULTYPLYERS_WL[0]-MULTYPLYERS_FL[0]-1:-MULTYPLYERS_FL[0]] mult_res_0;
    logic [MULTYPLYERS_WL[1]-MULTYPLYERS_FL[1]-1:-MULTYPLYERS_FL[1]] mult_res_1;
    logic [MULTYPLYERS_WL[2]-MULTYPLYERS_FL[2]-1:-MULTYPLYERS_FL[2]] mult_res_2;
    logic [MULTYPLYERS_WL[3]-MULTYPLYERS_FL[3]-1:-MULTYPLYERS_FL[3]] mult_res_3;
    logic [MULTYPLYERS_WL[4]-MULTYPLYERS_FL[4]-1:-MULTYPLYERS_FL[4]] mult_res_4;

    always_comb begin
        for (int i = 0; i < FIR_DIFF_COEFF_NUM; i++) begin
            if (i == 0) begin
                diff_res[i] = s_tdata - s_tdata_d[FIR_DIFF_ORDER-1];
            end else begin
                diff_res[i] = s_tdata_d[i-1] - s_tdata_d[FIR_DIFF_ORDER-1-i];
            end
        end
        
        if (ctrl) begin
            mult_res_0 = fir_integr_coeff_a0 * diff_res[0];
            mult_res_1 = fir_integr_coeff_a1 * diff_res[1];
            mult_res_2 = fir_integr_coeff_a0 * diff_res[2];
            mult_res_3 = 0;
            mult_res_4 = 0;

            summ_res[0] = mult_res_0  + mult_res_1;
            summ_res[1] = summ_res[0] + mult_res_2;
            summ_res[2] = summ_res[1] + mult_res_3;
            summ_res[3] = summ_res[2] + mult_res_4;
            summ_res[4] = summ_res[3];
        end else begin
            mult_res_0 = fir_diff_coeff_a4 * diff_res[0];
            mult_res_1 = fir_diff_coeff_a1 * diff_res[1];
            mult_res_2 = fir_diff_coeff_a2 * diff_res[2];
            mult_res_3 = fir_diff_coeff_a3 * diff_res[3];
            mult_res_4 = fir_diff_coeff_a4 * diff_res[4];

            summ_res[0] = mult_res_0 + mult_res_1;
            summ_res[1] = summ_res[0] + mult_res_2;
            summ_res[2] = summ_res[1] + mult_res_3;
            summ_res[3] = summ_res[2] + mult_res_4;
            summ_res[4] = summ_res[3] + loop_tdata[DELAY_FEEDBACK_LOOP-1];
        end
        m_tdata = summ_res[4];
    end
endmodule
