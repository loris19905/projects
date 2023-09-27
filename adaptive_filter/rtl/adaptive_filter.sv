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
                m_tdata       <= (summ_res[4][-7]) ? summ_res[4][7:-6] + 1 : summ_res[4][7:-6]; //округление
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

    logic [MULTYPLYERS_FL[0]-MULTYPLYERS_FL[1]-1:0] zeros_summ_res_0;
    logic [OP_SUMM_FL-MULTYPLYERS_FL[3]-1:0]        zeros_summ_res_2;
    logic [OP_SUMM_FL-MULTYPLYERS_FL[4]-1:0]        zeros_summ_res_3;

    assign zeros_summ_res_0 = '0;
    assign zeros_summ_res_2 = '0;
    assign zeros_summ_res_3 = '0;

    logic [OP_DIFF_FL-DIFF_COEFF_FL[0]-1:0] zeros_diff_mult_res_0;
    logic [OP_DIFF_FL-DIFF_COEFF_FL[1]-1:0] zeros_diff_mult_res_1;
    logic [OP_DIFF_FL-DIFF_COEFF_FL[2]-1:0] zeros_diff_mult_res_2;
    logic [OP_DIFF_FL-DIFF_COEFF_FL[3]-1:0] zeros_diff_mult_res_3;
    logic [OP_DIFF_FL-DIFF_COEFF_FL[4]-1:0] zeros_diff_mult_res_4;

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
                    diff_res[i] = $signed(s_tdata) - $signed(s_tdata_d[FIR_DIFF_ORDER-1]);
                end else begin
                    diff_res[i] = $signed(s_tdata_d[i-1]) - $signed(s_tdata_d[FIR_DIFF_ORDER-i-1]);
                end
            end
            
            if (ctrl) begin

                mult_res_0  = $signed({1'b0, fir_integr_coeff_a0}) * $signed(diff_res[0]);            //вставка доп нуля слева, чтобы трактовать как положительное знаковое число
                mult_res_1  = $signed({1'b0, fir_integr_coeff_a1}) * $signed(diff_res[1]); 
                mult_res_2  = $signed({1'b0, fir_integr_coeff_a0}) * $signed(diff_res[2]);
                mult_res_3  = '0;
                mult_res_4  = '0;

                summ_res[0] = $signed(mult_res_0 ) + $signed({mult_res_1, zeros_summ_res_0});       //добавление нулей для приведения положения запятой числа
                summ_res[1] = $signed(summ_res[0]) + $signed(mult_res_2);
                summ_res[2] = $signed(summ_res[1]) + $signed(mult_res_3);
                summ_res[3] = $signed(summ_res[2]) + $signed(mult_res_4);
                summ_res[4] = $signed(summ_res[3]) + $signed(loop_tdata[DELAY_FEEDBACK_LOOP-1]);
            
            end else begin

                mult_res_0  = $signed(fir_diff_coeff_a0) * $signed(diff_res[0]);
                mult_res_1  = $signed(fir_diff_coeff_a1) * $signed(diff_res[1]);
                mult_res_2  = $signed(fir_diff_coeff_a2) * $signed(diff_res[2]);
                mult_res_3  = $signed(fir_diff_coeff_a3) * $signed(diff_res[3]);
                mult_res_4  = $signed(fir_diff_coeff_a4) * $signed(diff_res[4]);

                summ_res[0] = $signed(mult_res_0 ) + $signed(mult_res_1);
                summ_res[1] = $signed(summ_res[0]) + $signed(mult_res_2);
                summ_res[2] = $signed(summ_res[1]) + $signed({mult_res_3, zeros_summ_res_2});
                summ_res[3] = $signed(summ_res[2]) + $signed({mult_res_4, zeros_summ_res_3});
                summ_res[4] = summ_res[3];
            
            end   
        end
        
    end
endmodule
