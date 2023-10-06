`timescale 1ns / 1ns

  /*
  * Title        : Адаптивный фильтр (дифференциатор, интегратор)
  * File         : adaptive_filter.sv
  * Description  : Реализация адаптивного фильтра: по ctrl = 1 фильтр работает в режиме интегратора, ctrl = 0 - в режиме дифференциатора.
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

    logic [FIR_DIFF_COEFF_NUM-1:0][OP_SUMM_WL-OP_SUMM_FL-1:-OP_SUMM_FL] summ_res;

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
                m_tdata       <= (summ_res[4][-7]) ? summ_res[4][7:-6] + 1 : summ_res[4][7:-6];
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

    logic [MULTYPLYERS_WL[0]-MULTYPLYERS_FL[0]-1:-MULTYPLYERS_FL[0]] mult_res_0;
    logic [MULTYPLYERS_WL[1]-MULTYPLYERS_FL[1]-1:-MULTYPLYERS_FL[1]] mult_res_1;
    logic [MULTYPLYERS_WL[2]-MULTYPLYERS_FL[2]-1:-MULTYPLYERS_FL[2]] mult_res_2;
    logic [MULTYPLYERS_WL[3]-MULTYPLYERS_FL[3]-1:-MULTYPLYERS_FL[3]] mult_res_3;
    logic [MULTYPLYERS_WL[4]-MULTYPLYERS_FL[4]-1:-MULTYPLYERS_FL[4]] mult_res_4;

    logic [OP_DIFF_WL+DIFF_COEFF_WL[1]-DIFF_COEFF_FL[1]-OP_DIFF_FL-1:-DIFF_COEFF_FL[1]-OP_DIFF_FL] mult_res_tmp_1;
    logic [OP_DIFF_WL+DIFF_COEFF_WL[2]-DIFF_COEFF_FL[2]-OP_DIFF_FL-1:-DIFF_COEFF_FL[2]-OP_DIFF_FL] mult_res_tmp_2;
    logic [OP_DIFF_WL+DIFF_COEFF_WL[3]-DIFF_COEFF_FL[3]-OP_DIFF_FL-1:-DIFF_COEFF_FL[3]-OP_DIFF_FL] mult_res_tmp_3;
    logic [OP_DIFF_WL+DIFF_COEFF_WL[4]-DIFF_COEFF_FL[4]-OP_DIFF_FL-1:-DIFF_COEFF_FL[4]-OP_DIFF_FL] mult_res_tmp_4;

    logic [MULTYPLYERS_FL[0]-MULTYPLYERS_FL[1]-1:0] zeros_summ_res_0;
    logic [OP_SUMM_FL-MULTYPLYERS_FL[3]-1:0]        zeros_summ_res_2;
    logic [OP_SUMM_FL-MULTYPLYERS_FL[4]-1:0]        zeros_summ_res_3;

    logic [DIFF_COEFF_FL[1]-INTEGR_COEFF_FL[1]-1:0] zeros_coeff_mult_1;
    logic [DIFF_COEFF_FL[2]-INTEGR_COEFF_FL[0]-1:0] zeros_coeff_mult_2;

    assign zeros_summ_res_0 = '0;
    assign zeros_summ_res_2 = '0;
    assign zeros_summ_res_3 = '0;

    assign zeros_coeff_mult_1 = '0;
    assign zeros_coeff_mult_2 = '0;

    logic [DIFF_COEFF_WL[0]-DIFF_COEFF_FL[0]-1:-DIFF_COEFF_FL[0]] mult_coeff_0;
    logic [DIFF_COEFF_WL[1]-DIFF_COEFF_FL[1]-1:-DIFF_COEFF_FL[1]] mult_coeff_1;
    logic [DIFF_COEFF_WL[2]-DIFF_COEFF_FL[2]-1:-DIFF_COEFF_FL[2]] mult_coeff_2;
    logic [DIFF_COEFF_WL[3]-DIFF_COEFF_FL[3]-1:-DIFF_COEFF_FL[3]] mult_coeff_3;
    logic [DIFF_COEFF_WL[4]-DIFF_COEFF_FL[4]-1:-DIFF_COEFF_FL[4]] mult_coeff_4;


    always_comb begin
        if (srst) begin
            mult_res_0     = '0;
            mult_res_1     = '0;
            mult_res_2     = '0;
            mult_res_3     = '0;
            mult_res_4     = '0;
            summ_res       = '0; 
            mult_res_tmp_1 = '0;
            mult_res_tmp_2 = '0;  
            mult_res_tmp_3 = '0;  
            mult_res_tmp_4 = '0;
        end else begin

            for (int i = 0; i < FIR_DIFF_COEFF_NUM; i++) begin
                if (i == 0) begin
                    diff_res[i] = $signed(s_tdata) - $signed(s_tdata_d[FIR_DIFF_ORDER-1]);
                end else begin
                    diff_res[i] = $signed(s_tdata_d[i-1]) - $signed(s_tdata_d[FIR_DIFF_ORDER-i-1]);
                end
            end
            
            if (ctrl) begin

                mult_coeff_0 = {'0, fir_integr_coeff_a0};
                mult_coeff_1 = {'0, fir_integr_coeff_a1, zeros_coeff_mult_1};
                mult_coeff_2 = {'0, fir_integr_coeff_a0, zeros_coeff_mult_2};
                mult_coeff_3 = '0;
                mult_coeff_4 = '0;
            
            end else begin

                mult_coeff_0 = fir_diff_coeff_a0;
                mult_coeff_1 = fir_diff_coeff_a1;
                mult_coeff_2 = fir_diff_coeff_a2;
                mult_coeff_3 = fir_diff_coeff_a3;
                mult_coeff_4 = fir_diff_coeff_a4;    
            
            end

            mult_res_0      = $signed(mult_coeff_0) * $signed(diff_res[0]);

            mult_res_tmp_1  = $signed(mult_coeff_1) * $signed(diff_res[1]);
            mult_res_1      = (mult_res_tmp_1[-MULTYPLYERS_FL[1]-1]) ? mult_res_tmp_1[MULTYPLYERS_WL[1]-MULTYPLYERS_FL[1]-1:-MULTYPLYERS_FL[1]] + 1 : mult_res_tmp_1[MULTYPLYERS_WL[1]-MULTYPLYERS_FL[1]-1:-MULTYPLYERS_FL[1]];

            mult_res_tmp_2  = $signed(mult_coeff_2) * $signed(diff_res[2]);
            mult_res_2      = (mult_res_tmp_2[-MULTYPLYERS_FL[2]-1]) ? mult_res_tmp_2[MULTYPLYERS_WL[2]-MULTYPLYERS_FL[2]-1:-MULTYPLYERS_FL[2]] + 1 : mult_res_tmp_2[MULTYPLYERS_WL[2]-MULTYPLYERS_FL[2]-1:-MULTYPLYERS_FL[2]];

            mult_res_tmp_3  = $signed(mult_coeff_3) * $signed(diff_res[3]);
            mult_res_3      = (mult_res_tmp_3[-MULTYPLYERS_FL[3]-1]) ? mult_res_tmp_3[MULTYPLYERS_WL[3]-MULTYPLYERS_FL[3]-1:-MULTYPLYERS_FL[3]] + 1 : mult_res_tmp_3[MULTYPLYERS_WL[3]-MULTYPLYERS_FL[3]-1:-MULTYPLYERS_FL[3]];
            
            mult_res_tmp_4  = $signed(mult_coeff_4) * $signed(diff_res[4]);
            mult_res_4      = (mult_res_tmp_4[-MULTYPLYERS_FL[4]-1]) ? mult_res_tmp_4[MULTYPLYERS_WL[4]-MULTYPLYERS_FL[4]-1:-MULTYPLYERS_FL[4]] + 1 : mult_res_tmp_4[MULTYPLYERS_WL[4]-MULTYPLYERS_FL[4]-1:-MULTYPLYERS_FL[4]];

            summ_res[0] = $signed(mult_res_0 ) + $signed({mult_res_1, zeros_summ_res_0});
            summ_res[1] = $signed(summ_res[0]) + $signed(mult_res_2);
            summ_res[2] = $signed(summ_res[1]) + $signed({mult_res_3, zeros_summ_res_2});
            summ_res[3] = $signed(summ_res[2]) + $signed({mult_res_4, zeros_summ_res_3});
            summ_res[4] = $signed(summ_res[3]) + $signed(loop_tdata[DELAY_FEEDBACK_LOOP-1]);

        end
        
    end

    //Debug
    (* synthesys_off *)

    localparam DATA_LENGTH = 128;
    localparam DATA_DIR    = "C:\\MyFolder\\RemoteFolder\\projects\\adaptive_filter\\tbn\\data\\";

    logic [$clog2(DATA_LENGTH)-1:0] cnt_data;
    logic                           finish_data_transfer;

    logic [MULTYPLYERS_WL[0]-MULTYPLYERS_FL[0]-1:-MULTYPLYERS_FL[0]] mult_res_0_mem [DATA_LENGTH-1:0];
    logic [MULTYPLYERS_WL[1]-MULTYPLYERS_FL[1]-1:-MULTYPLYERS_FL[1]] mult_res_1_mem [DATA_LENGTH-1:0];
    logic [MULTYPLYERS_WL[2]-MULTYPLYERS_FL[2]-1:-MULTYPLYERS_FL[2]] mult_res_2_mem [DATA_LENGTH-1:0];
    logic [MULTYPLYERS_WL[3]-MULTYPLYERS_FL[3]-1:-MULTYPLYERS_FL[3]] mult_res_3_mem [DATA_LENGTH-1:0];
    logic [MULTYPLYERS_WL[4]-MULTYPLYERS_FL[4]-1:-MULTYPLYERS_FL[4]] mult_res_4_mem [DATA_LENGTH-1:0];

    logic [OP_DIFF_WL-OP_DIFF_FL-1:-OP_DIFF_FL] diff_res_mem [DATA_LENGTH-1:0][FIR_DIFF_COEFF_NUM-1:0];

    always_ff @(posedge clk) begin
        if (srst) begin
            cnt_data             <= '0;

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
            if (s_tvalid) begin
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
                cnt_data              <= cnt_data;
                mult_res_0_mem        <= mult_res_0_mem;
                mult_res_1_mem        <= mult_res_1_mem;
                mult_res_2_mem        <= mult_res_2_mem;
                mult_res_3_mem        <= mult_res_3_mem;
                mult_res_4_mem        <= mult_res_4_mem;
                diff_res_mem          <= diff_res_mem;
                finish_data_transfer  <= finish_data_transfer;
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
            $writememb({DATA_DIR, "diff.txt"}, diff_res_mem);
        end
    end

endmodule
