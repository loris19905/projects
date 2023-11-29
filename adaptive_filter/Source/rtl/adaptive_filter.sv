`timescale 1ns / 1ns

//Project name: "Adaptive filter"
//Author:        Kavruk A.
//File description: RTL

module adaptive_filter 
    import adaptive_filter_pkg::*;
    #(SIM_EN = 0
    )(	
    input  logic        clk,
    input  logic        srst,
    input  logic        ctrl,

    input  logic [13:0] s_tdata,
    input  logic        s_tvalid,

    output logic [13:0] m_tdata,
    output logic        m_tvalid
);

    localparam REG_ZERO_START_ADDR = 6;
    localparam DELAY_FEEDBACK_LOOP = 2;

    //Коэффициенты импульсной характеристики дифференциатора
    logic [DIFF_COEFF_WL[0]-1:0] fir_diff_coeff_a0;
    logic [DIFF_COEFF_WL[1]-1:0] fir_diff_coeff_a1;
    logic [DIFF_COEFF_WL[2]-1:0] fir_diff_coeff_a2;
    logic [DIFF_COEFF_WL[3]-1:0] fir_diff_coeff_a3;
    logic [DIFF_COEFF_WL[4]-1:0] fir_diff_coeff_a4;

    assign fir_diff_coeff_a0 = 8'hFF;
    assign fir_diff_coeff_a1 = 9'h019;
    assign fir_diff_coeff_a2 = 9'h1CD;
    assign fir_diff_coeff_a3 = 6'h07;
    assign fir_diff_coeff_a4 = 7'h13;

    //Коэффициенты импульсной характеристики интегратора
    logic [INTEGR_COEFF_WL[0]-1:0] fir_integr_coeff_a0;
    logic [INTEGR_COEFF_WL[1]-1:0] fir_integr_coeff_a1;

    assign fir_integr_coeff_a0 = 7'h17;
    assign fir_integr_coeff_a1 = 6'h29; 

    //Объявление регистровых переменных
    logic [FIR_DIFF_ORDER-1:0     ][WORDLENGTH-1:0] s_tdata_d;
    logic [DELAY_FEEDBACK_LOOP-1:0][OP_SUMM_WL-1:0] loop_tdata;
    logic                                           s_tvalid_d;

    logic [WORDLENGTH-1:0]                          s_tdata_reg;
    logic                                           s_tvalid_reg;
    logic                                           ctrl_reg;

    logic [FIR_DIFF_COEFF_NUM-1:0][OP_SUMM_WL-1:0]  summ_res;

    //Защелкивание входных данных
    always_ff @(posedge clk) begin
        if (srst) begin
            s_tdata_reg  <= '0;
            s_tvalid_reg <= '0;
            ctrl_reg     <= '0;  
        end else begin
            s_tdata_reg  <= s_tdata; 
            s_tvalid_reg <= s_tvalid;
            ctrl_reg     <= ctrl;
        end
    end

    //Сдвиговый регистр. Начиная с регистра REG_ZERO_START_ADDR на вход подаются нули при работе в режиме интегратора
    always_ff @(posedge clk) begin
        if (srst) begin
            s_tdata_d    <= '0;
        end else begin
            for (int i = 0; i < FIR_DIFF_ORDER; i++) begin
                if (i == 0) begin
                    s_tdata_d[i] <= (s_tvalid_reg) ? s_tdata_reg : s_tdata_d[i];
                end else begin
                    if (ctrl_reg) begin
                        if (s_tvalid_reg) begin
                            s_tdata_d[i] <= (i >= REG_ZERO_START_ADDR) ? '0 : s_tdata_d[i-1];
                        end else begin    
                            s_tdata_d[i] <= s_tdata_d[i];
                        end
                    end else begin
                        s_tdata_d[i] <= (s_tvalid_reg) ? s_tdata_d[i-1] : s_tdata_d[i];
                    end
                end
            end
        end
    end

    //Защелкивание выходного потока данных в регистры c одновременным приведением поступающих данных к ширине выходных данных + округление
    //В этом же блоке осуществляется передача данных по петле обратной связи
    always_ff @(posedge clk) begin
        if (srst) begin
            loop_tdata   <= '0;
            m_tdata      <= '0;
            s_tvalid_d   <= '0;
            m_tvalid     <= '0;  
        end else begin
            if (s_tvalid_reg) begin
                loop_tdata[0] <= summ_res[FIR_DIFF_COEFF_NUM-1];
                m_tdata       <= (summ_res[4][OP_SUMM_FL-FRACTIONAL_LENGTH-1]) ? summ_res[4][WORDLENGTH+OP_SUMM_FL-FRACTIONAL_LENGTH-1:OP_SUMM_FL-FRACTIONAL_LENGTH] + 1 : 
                                                                                 summ_res[4][WORDLENGTH+OP_SUMM_FL-FRACTIONAL_LENGTH-1:OP_SUMM_FL-FRACTIONAL_LENGTH];
            end else begin
                loop_tdata[0] <= loop_tdata[0];
                m_tdata       <= m_tdata;
            end

            if (s_tvalid_d) begin
                loop_tdata[DELAY_FEEDBACK_LOOP-1] <= loop_tdata[0];
            end else begin
                loop_tdata[DELAY_FEEDBACK_LOOP-1] <= loop_tdata[DELAY_FEEDBACK_LOOP-1];
            end

            m_tvalid     <= s_tvalid_reg;
            s_tvalid_d   <= s_tvalid_reg;
        end  
    end

    /*
        По приходящему сигналу ctrl происходит переключение между коэффициентами интегратора и дифференциатора
        Блок умножения имеет фиксированный размер для поступающих операндов, поэтому ширина mult_coeff_i определяется
        наибольшей шириной двух коэффициентов, которые могут прийти на i-ый блок умножения
        В данном случае ширина коэффициентов интегратора окалазь меньше, чем ширина коэффициентов дифференциатора.
        Добавив справа "0", сами коэффициенты не поменяются, и при этом буддут удовлетворять заявленной ширине операнда умножителя.
        Дополнительный "0" слева - знаковый бит
    */

    logic [DIFF_COEFF_WL[0]-1:0]                    mult_coeff_0;
    logic [DIFF_COEFF_WL[1]-1:0]                    mult_coeff_1;
    logic [DIFF_COEFF_WL[2]-1:0]                    mult_coeff_2;
    logic [DIFF_COEFF_WL[3]-1:0]                    mult_coeff_3;
    logic [DIFF_COEFF_WL[4]-1:0]                    mult_coeff_4;

    logic [DIFF_COEFF_FL[1]-INTEGR_COEFF_FL[1]-1:0] zeros_coeff_mult_1;
    logic [DIFF_COEFF_FL[2]-INTEGR_COEFF_FL[0]-1:0] zeros_coeff_mult_2;

    assign zeros_coeff_mult_1 = '0;
    assign zeros_coeff_mult_2 = '0;

    always_ff @(posedge clk) begin
        if (ctrl) begin
                mult_coeff_0 <= {'0, fir_integr_coeff_a0};
                mult_coeff_1 <= {'0, fir_integr_coeff_a1, zeros_coeff_mult_1};
                mult_coeff_2 <= {'0, fir_integr_coeff_a0, zeros_coeff_mult_2};
                mult_coeff_3 <= '0;
                mult_coeff_4 <= '0;    
        end else begin
                mult_coeff_0 <= fir_diff_coeff_a0;
                mult_coeff_1 <= fir_diff_coeff_a1;
                mult_coeff_2 <= fir_diff_coeff_a2;
                mult_coeff_3 <= fir_diff_coeff_a3;
                mult_coeff_4 <= fir_diff_coeff_a4;
        end
    end

    //Вычисление результатов блоков вычитания, умножения и сложения
    logic [FIR_DIFF_COEFF_NUM-1:0][OP_DIFF_WL-OP_DIFF_FL-1:-OP_DIFF_FL] diff_res;

    logic [MULTYPLYERS_WL[0]-1:0]                                       mult_res_0;
    logic [MULTYPLYERS_WL[1]-1:0]                                       mult_res_1;
    logic [MULTYPLYERS_WL[2]-1:0]                                       mult_res_2;
    logic [MULTYPLYERS_WL[3]-1:0]                                       mult_res_3;
    logic [MULTYPLYERS_WL[4]-1:0]                                       mult_res_4;

    logic [OP_DIFF_WL+DIFF_COEFF_WL[1]-1:0]                             mult_res_tmp_1;
    logic [OP_DIFF_WL+DIFF_COEFF_WL[2]-1:0]                             mult_res_tmp_2;
    logic [OP_DIFF_WL+DIFF_COEFF_WL[3]-1:0]                             mult_res_tmp_3;
    logic [OP_DIFF_WL+DIFF_COEFF_WL[4]-1:0]                             mult_res_tmp_4;

    logic [MULTYPLYERS_FL[0]-MULTYPLYERS_FL[1]-1:0]                     zeros_summ_res_0;
    logic [OP_SUMM_FL-MULTYPLYERS_FL[3]-1:0]                            zeros_summ_res_2;
    logic [OP_SUMM_FL-MULTYPLYERS_FL[4]-1:0]                            zeros_summ_res_3;

    

    logic [OP_SUMM_WL-1:0]                                              feedback_operand;

    assign zeros_summ_res_0 = '0;
    assign zeros_summ_res_2 = '0;
    assign zeros_summ_res_3 = '0;

    /*
        При описании блока использовались встроенные функции Verilog $signed(), который учитывает при вычислении смену знака.
        При вычислении использовалось округление к ближайшему.
        УМНОЖЕНИЕ:
        Промежуточный результат рассчитывался с полной разрядностью (например, первый операнд имеет ширину W1, 
        второй W2, тогда выходной результат - W1+W2). Конечный результат - результат округления промежуточного результата к заявленной ширине. Ход округления:
        -- расчет в полной разрядности,
        -- определяем диапазон бит, который необходимо взять из выходного результата, ориентируясь на то, что все-таки число дробное
        -- определение величины бита (результата полной разрядности), который располагается относительно фиксированной точки в позиции (-FRACTIONAL_LENGT-1)
        -- если бит = "1", прибавляем к усеченному результату "1", если нет - выходной результат вычислительного блока равен усеченному результату полной разрядности
        СУММИРОВАНИЕ:
        При суммировании также необходимо помнить, что первоначально числа дробные, т.е. целую часть необходимо складывать с целой, дробную - с дробной. Соответственно, 
        если дробные части не сходятся, то операнд с наименьшей дробной частью необходимо справа дополнить нулями
    */
    always_comb begin
        if (srst) begin
            mult_res_0       = '0;
            mult_res_1       = '0;
            mult_res_2       = '0;
            mult_res_3       = '0;
            mult_res_4       = '0;
            summ_res         = '0;
            mult_res_tmp_1   = '0;
            mult_res_tmp_2   = '0;  
            mult_res_tmp_3   = '0;  
            mult_res_tmp_4   = '0;
            feedback_operand = '0;
        end else begin
            for (int i = 0; i < FIR_DIFF_COEFF_NUM; i++) begin
                if (i == 0) begin
                    diff_res[i] = $signed(s_tdata_reg) - $signed(s_tdata_d[FIR_DIFF_ORDER-1]);
                end else begin
                    diff_res[i] = $signed(s_tdata_d[i-1]) - $signed(s_tdata_d[FIR_DIFF_ORDER-i-1]);
                end
            end

            mult_res_0     = $signed(mult_coeff_0) * $signed(diff_res[0]);

            mult_res_tmp_1 = $signed(mult_coeff_1) * $signed(diff_res[1]);
            mult_res_1     = (mult_res_tmp_1[DIFF_COEFF_FL[1]+OP_DIFF_FL-MULTYPLYERS_FL[1]-1]) ? mult_res_tmp_1[MULTYPLYERS_WL[1]+DIFF_COEFF_FL[1]+OP_DIFF_FL-MULTYPLYERS_FL[1]-1:DIFF_COEFF_FL[1]+OP_DIFF_FL-MULTYPLYERS_FL[1]] + 1 : 
                                                                                                 mult_res_tmp_1[MULTYPLYERS_WL[1]+DIFF_COEFF_FL[1]+OP_DIFF_FL-MULTYPLYERS_FL[1]-1:DIFF_COEFF_FL[1]+OP_DIFF_FL-MULTYPLYERS_FL[1]];

            mult_res_tmp_2 = $signed(mult_coeff_2) * $signed(diff_res[2]);
            mult_res_2     = (mult_res_tmp_2[DIFF_COEFF_FL[2]+OP_DIFF_FL-MULTYPLYERS_FL[2]-1]) ? mult_res_tmp_2[MULTYPLYERS_WL[2]+DIFF_COEFF_FL[2]+OP_DIFF_FL-MULTYPLYERS_FL[2]-1:DIFF_COEFF_FL[2]+OP_DIFF_FL-MULTYPLYERS_FL[2]] + 1 : 
                                                                                                 mult_res_tmp_2[MULTYPLYERS_WL[2]+DIFF_COEFF_FL[2]+OP_DIFF_FL-MULTYPLYERS_FL[2]-1:DIFF_COEFF_FL[2]+OP_DIFF_FL-MULTYPLYERS_FL[2]];

            mult_res_tmp_3 = $signed(mult_coeff_3) * $signed(diff_res[3]);
            mult_res_3     = (mult_res_tmp_3[DIFF_COEFF_FL[3]+OP_DIFF_FL-MULTYPLYERS_FL[3]-1]) ? mult_res_tmp_3[MULTYPLYERS_WL[3]+DIFF_COEFF_FL[3]+OP_DIFF_FL-MULTYPLYERS_FL[3]-1:DIFF_COEFF_FL[3]+OP_DIFF_FL-MULTYPLYERS_FL[3]] + 1 : 
                                                                                                 mult_res_tmp_3[MULTYPLYERS_WL[3]+DIFF_COEFF_FL[3]+OP_DIFF_FL-MULTYPLYERS_FL[3]-1:DIFF_COEFF_FL[3]+OP_DIFF_FL-MULTYPLYERS_FL[3]];
            
            mult_res_tmp_4 = $signed(mult_coeff_4) * $signed(diff_res[4]);
            mult_res_4     = (mult_res_tmp_4[DIFF_COEFF_FL[4]+OP_DIFF_FL-MULTYPLYERS_FL[4]-1]) ? mult_res_tmp_4[MULTYPLYERS_WL[4]+DIFF_COEFF_FL[4]+OP_DIFF_FL-MULTYPLYERS_FL[4]-1:DIFF_COEFF_FL[4]+OP_DIFF_FL-MULTYPLYERS_FL[4]] + 1 : 
                                                                                                 mult_res_tmp_4[MULTYPLYERS_WL[4]+DIFF_COEFF_FL[4]+OP_DIFF_FL-MULTYPLYERS_FL[4]-1:DIFF_COEFF_FL[4]+OP_DIFF_FL-MULTYPLYERS_FL[4]];

            summ_res[0] = $signed(mult_res_0 ) + $signed({mult_res_1, zeros_summ_res_0});
            summ_res[1] = $signed(summ_res[0]) + $signed(mult_res_2);
            summ_res[2] = $signed(summ_res[1]) + $signed({mult_res_3, zeros_summ_res_2});
            summ_res[3] = $signed(summ_res[2]) + $signed({mult_res_4, zeros_summ_res_3});

            feedback_operand = (ctrl_reg) ? loop_tdata[DELAY_FEEDBACK_LOOP-1] : '0;
            summ_res[4]      = $signed(summ_res[3]) + $signed(feedback_operand);
        end
    end

    /*
        Секция предназначенная для проверки промежуточных результатов блоков умножения и вычитания.
        В модуле объявляется память под каждый вычислительный блок. По окончании принятия данных происходит запись 
        файл.

        Данный блок относится к несинтезируемым структурам. При симуляции параметр SIM_EN можно положить равными 1, в
        таком случае сгенерируется несинтезуемая часть.

        По умолчанию SIM_EN = 0 => на этапе синтеза данная часть не будет сгенерирована.
    */
    generate
        if (SIM_EN) begin

            localparam DATA_LENGTH = 128;
            localparam DATA_DIR    = "C:\\MyFolder\\RemoteFolder\\projects\\adaptive_filter\\Source\\tbn\\data\\";

            logic [$clog2(DATA_LENGTH)-1:0] cnt_data;
            logic                           finish_data_transfer;

            logic [MULTYPLYERS_WL[0]-1:0] mult_res_0_mem [DATA_LENGTH-1:0];
            logic [MULTYPLYERS_WL[1]-1:0] mult_res_1_mem [DATA_LENGTH-1:0];
            logic [MULTYPLYERS_WL[2]-1:0] mult_res_2_mem [DATA_LENGTH-1:0];
            logic [MULTYPLYERS_WL[3]-1:0] mult_res_3_mem [DATA_LENGTH-1:0];
            logic [MULTYPLYERS_WL[4]-1:0] mult_res_4_mem [DATA_LENGTH-1:0];

            logic [OP_DIFF_WL-OP_DIFF_FL-1:-OP_DIFF_FL] diff_res_mem [DATA_LENGTH-1:0][FIR_DIFF_COEFF_NUM-1:0];

            always_ff @(posedge clk) begin
                if (srst) begin
                    cnt_data <= '0;

                    foreach (mult_res_0_mem[element]) begin
                        mult_res_0_mem[element] <= '0;
                    end

                    foreach (mult_res_1_mem[element]) begin
                        mult_res_1_mem[element] <= '0;
                    end

                    foreach (mult_res_2_mem[element]) begin
                        mult_res_2_mem[element] <= '0;
                    end

                    foreach (mult_res_3_mem[element]) begin
                        mult_res_3_mem[element] <= '0;
                    end

                    foreach (mult_res_4_mem[element]) begin
                        mult_res_4_mem[element] <= '0;
                    end

                    for (int i = 0; i < DATA_LENGTH; i++) begin
                        for (int j = 0; j < FIR_DIFF_COEFF_NUM; j++) begin
                            diff_res_mem[i][j] <= '0;    
                        end
                    end

                end else begin
                    if (s_tvalid_reg) begin
                        cnt_data                 <= cnt_data + 1;
                        mult_res_0_mem[cnt_data] <= mult_res_0;
                        mult_res_1_mem[cnt_data] <= mult_res_1;
                        mult_res_2_mem[cnt_data] <= mult_res_2;
                        mult_res_3_mem[cnt_data] <= mult_res_3;
                        mult_res_4_mem[cnt_data] <= mult_res_4;

                        for (int i = 0; i < FIR_DIFF_COEFF_NUM; i++) begin
                            diff_res_mem[cnt_data][i] <= diff_res[i];
                        end

                        finish_data_transfer     <= (cnt_data == (DATA_LENGTH - 1)) ? 1'b1 : 1'b0;
                    end else begin
                        cnt_data             <= cnt_data;
                        mult_res_0_mem       <= mult_res_0_mem;
                        mult_res_1_mem       <= mult_res_1_mem;
                        mult_res_2_mem       <= mult_res_2_mem;
                        mult_res_3_mem       <= mult_res_3_mem;
                        mult_res_4_mem       <= mult_res_4_mem;
                        diff_res_mem         <= diff_res_mem;
                        finish_data_transfer <= finish_data_transfer;
                    end
                end
            end

            always @(*) begin
                if (finish_data_transfer) begin
                    $writememb({DATA_DIR, "mult_0.txt"}, mult_res_0_mem);
                    $writememb({DATA_DIR, "mult_1.txt"}, mult_res_1_mem);
                    $writememb({DATA_DIR, "mult_2.txt"}, mult_res_2_mem);
                    $writememb({DATA_DIR, "mult_3.txt"}, mult_res_3_mem);
                    $writememb({DATA_DIR, "mult_4.txt"}, mult_res_4_mem);
                    $writememb({DATA_DIR, "diff.txt"  }, diff_res_mem  );
                end
            end
        end
    endgenerate

endmodule
