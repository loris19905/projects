`timescale 1ns / 1ps
/*
 * Title        :   Двоичный поиск в памяти
 * File         :   binary_search.sv
 * Description  :   Модуль реализует двоичный поиск двух индексов, которые наиболее близки к искомому входному значению alpha (предполагаем, что 
                    ситуация, когда входное число идентично некоторому числу в памяти, практически невозможна); данные в загружаемом файле предварительно отсортированы
 */

module binary_search 
#(
    parameter SIM_EN          = 0,
    parameter DATA_TYPE       = "fixed", // fixed / single
    parameter DATA_WIDTH      = 16,
    parameter CODEBOOK_LENGTH = 1000,
    parameter RAM_TYPE        = "LOW_LATENCY", // LOW_LATENCY, HIGH_PERFOMANCE
    parameter ALPHA_FILE      = "/home/ubuntu/Projects/RSA/Quantizer/alpha.mif"  
)(
    input  logic                  clk_i,
    input  logic                  srst_i,

    input  logic [DATA_WIDTH-1:0] s_alpha_tdata,
    output logic                  s_alpha_tready,
    input  logic                  s_alpha_tvalid,

    output logic [DATA_WIDTH-1:0] m_idx_tdata,
    input  logic                  m_idx_tready,
    output logic                  m_idx_tvalid 
);
    
    localparam COMPARE_DELAY   = (DATA_TYPE == "fixed") ? 1 : 3;      //задержку модуля сравнения для обработки single надо уточнять (либо лежит в IP-ядре либо в реализованном модуле)
    localparam READ_DELAY      = (RAM_TYPE == "LOW_LATENCY") ? 1 : 2;
    localparam RAM_INPUT_DELAY = 1;
    localparam CHECK_DELAY     = 2;

    localparam MAX_IDX_VAL   = CODEBOOK_LENGTH - 1;
    localparam MIN_IDX_VAL   = 0;
    localparam MAX_DELAY     = 8;
    localparam TOTAL_DELAY   = COMPARE_DELAY + READ_DELAY + RAM_INPUT_DELAY;

    typedef enum logic [2:0] {IDLE          = 0,
                              START_SEARCH  = 1,
                              SEARCH        = 2,
                              FIND_IDX      = 3,
                              CHECK_NEAREST = 4,
                              SEND_DATA     = 5     
                            } data_flow_state; 
    data_flow_state state;
    data_flow_state next_state;

    assign s_alpha_tready = (state == IDLE) ? 1'b1 : 1'b0;

    logic [DATA_WIDTH-1:0] alpha_tdata_reg;
    logic                  alpha_tvalid_reg;

    logic [DATA_WIDTH-1:0] alpha_ram_tdata;
    logic                  alpha_ram_tvalid;

    logic [DATA_WIDTH-1:0] alpha_ram_tdata_reg;
    logic                  alpha_ram_tvalid_reg;

    logic                  is_more_tdata;
    logic                  is_more_tvalid;

    logic [DATA_WIDTH-1:0] low_idx_tdata;
    logic                  low_idx_tvalid;

    logic [DATA_WIDTH-1:0] high_idx_tdata;
    logic                  high_idx_tvalid;

    logic [DATA_WIDTH-1:0] half_idx_tdata;
    logic                  half_idx_tvalid;

    logic [DATA_WIDTH-1:0] half_idx_tdata_reg;
    logic                  half_idx_tvalid_reg;

    logic [DATA_WIDTH-1:0] s_ram_idx_tdata;
    logic                  s_ram_idx_tvalid;

    logic                  find_two_idx;

    logic [DATA_WIDTH-1:0] compare_diff_tdata_1;
    logic [DATA_WIDTH-1:0] compare_diff_tdata_2;
    logic                  select_idx;

    logic [$clog2(MAX_DELAY)-1:0] cnt_repeat_val;

    always_ff @(posedge clk_i) begin
        if (srst_i) begin
            alpha_tdata_reg     <= 0;
            alpha_tvalid_reg    <= 0;
            cnt_repeat_val      <= 0;
            is_more_tdata       <= 0;
            is_more_tvalid      <= 0;
            high_idx_tdata      <= 0;
            high_idx_tvalid     <= 0;
            low_idx_tdata       <= 0;
            low_idx_tvalid      <= 0;
            half_idx_tdata_reg  <= 0;
            half_idx_tvalid_reg <= 0;
        end else begin
            if (s_alpha_tready && s_alpha_tvalid) begin
                alpha_tdata_reg  <= s_alpha_tdata;
                alpha_tvalid_reg <= s_alpha_tvalid;
            end else begin
                alpha_tdata_reg  <= alpha_tdata_reg;
                alpha_tvalid_reg <= (state == IDLE) ? 1'b0 : alpha_tvalid_reg;    
            end
            if (state != IDLE) begin
                cnt_repeat_val <= (cnt_repeat_val == TOTAL_DELAY) ? 0 : cnt_repeat_val + 1;
                if (cnt_repeat_val == 0) begin
                    if (state == START_SEARCH) begin
                        high_idx_tdata  <= MAX_IDX_VAL;
                        low_idx_tdata   <= MIN_IDX_VAL;
                        high_idx_tvalid <= 1'b1;
                        low_idx_tvalid  <= 1'b1;
                    end else begin
                        if (is_more_tvalid) begin
                            high_idx_tdata  <= (is_more_tdata) ? high_idx_tdata : half_idx_tdata;
                            low_idx_tdata   <= (is_more_tdata) ? half_idx_tdata : low_idx_tdata;
                            high_idx_tvalid <= 1'b1;
                            low_idx_tvalid  <= 1'b1;  
                        end else begin
                            high_idx_tdata  <= high_idx_tdata;
                            low_idx_tdata   <= low_idx_tdata;
                            high_idx_tvalid <= 1'b0;
                            low_idx_tvalid  <= 1'b0;
                        end
                    end
                end else begin
                    high_idx_tdata  <= high_idx_tdata;
                    low_idx_tdata   <= low_idx_tdata;
                    high_idx_tvalid <= 1'b0;
                    low_idx_tvalid  <= 1'b0;     
                end
                is_more_tdata  <= alpha_tdata_reg > alpha_ram_tdata;
                is_more_tvalid <= (state == CHECK_NEAREST) ? 1'b0 : alpha_ram_tvalid && alpha_tvalid_reg;   
            end else begin
                cnt_repeat_val  <= 0;
                high_idx_tvalid <= 0;
                low_idx_tvalid  <= 0;
            end
            half_idx_tdata_reg  <= half_idx_tdata;
            half_idx_tvalid_reg <= half_idx_tvalid;
        end
    end
    
    logic [DATA_WIDTH-1:0]      idx_diff_tdata;

    logic [1:0][DATA_WIDTH-1:0] idx_buffer_tdata;
    logic                       idx_buffer_tvalid;

    logic                       cnt_upload_idx;

    always_ff @(posedge clk_i) begin
        if (srst_i) begin
            idx_buffer_tdata     <= 0;
            cnt_upload_idx       <= 0;
            alpha_ram_tvalid     <= 0;
            find_two_idx         <= 0;
            alpha_ram_tdata_reg  <= 0;
            alpha_ram_tvalid_reg <= 0;
            m_idx_tdata          <= 0;  
        end else begin
            if (state == FIND_IDX) begin
                idx_buffer_tdata  <= idx_buffer_tdata;
                idx_buffer_tvalid <= 1'b1;
                cnt_upload_idx    <= cnt_upload_idx + 1; 
            end else begin
                idx_buffer_tdata[0] <= (low_idx_tvalid) ? low_idx_tdata : idx_buffer_tdata[0];
                idx_buffer_tdata[1] <= (high_idx_tvalid) ? high_idx_tdata : idx_buffer_tdata[1];
                idx_buffer_tvalid   <= find_two_idx; 
                cnt_upload_idx      <= 0;
            end
            m_idx_tdata          <= idx_buffer_tdata[select_idx];
            alpha_ram_tvalid     <= s_ram_idx_tvalid;
            find_two_idx         <= (idx_diff_tdata == 1);
            alpha_ram_tdata_reg  <= alpha_ram_tdata;
            alpha_ram_tvalid_reg <= (state == CHECK_NEAREST) ? alpha_ram_tvalid : 1'b0;    
        end
    end

    always_comb begin
        half_idx_tdata       = (high_idx_tdata + low_idx_tdata) >> 1;    //возможное улучшение таймингов: разбить триггером суммирование и битовый сдвиг
        half_idx_tvalid      = high_idx_tvalid;
        idx_diff_tdata       =  high_idx_tdata - low_idx_tdata;
        s_ram_idx_tdata      = (state == FIND_IDX) ? idx_buffer_tdata[cnt_upload_idx] : half_idx_tdata_reg;
        s_ram_idx_tvalid     = (state == FIND_IDX) ? 1'b1 : half_idx_tvalid_reg;
        compare_diff_tdata_1 = alpha_ram_tdata - alpha_tdata_reg;
        compare_diff_tdata_2 = alpha_tdata_reg - alpha_ram_tdata_reg;
        select_idx           = compare_diff_tdata_1 < compare_diff_tdata_2;
        m_idx_tvalid         = (state == SEND_DATA) ? 1'b1 : 1'b0;
    end

    memory_sdpram_1clk #(
        .RAM_DEPTH       (CODEBOOK_LENGTH),
        .RAM_WIDTH       (DATA_WIDTH     ),
        .RAM_PERFORMANCE (RAM_TYPE       ),
        .INIT_FILE       (ALPHA_FILE     )
    ) bram (
        .clka            (clk_i          ),
        .wea             (1'b0           ),
        .addra           (0              ),
        .dina            (0              ),

        .rstb            (srst_i          ),
        .addrb           (s_ram_idx_tdata ),
        .enb             (s_ram_idx_tvalid),
        .regceb          (1'b1            ),
        .doutb           (alpha_ram_tdata )
    );

    always_ff @(posedge clk_i) begin
        if (srst_i) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        case (state)
            IDLE: 
                begin
                    next_state = (s_alpha_tready && s_alpha_tvalid) ? START_SEARCH : IDLE;
                end
            START_SEARCH: 
                begin
                    next_state = (alpha_tvalid_reg && alpha_ram_tvalid) ? SEARCH : START_SEARCH;
                end
            SEARCH:
                begin
                    next_state = (find_two_idx) ? FIND_IDX : SEARCH;
                end
            FIND_IDX:
                begin
                    next_state = (cnt_upload_idx == 1) ? CHECK_NEAREST : FIND_IDX;               
                end
            CHECK_NEAREST:
                begin
                    next_state = SEND_DATA; //  если выбран RAM_TYPE  = "HIGH_PERFOMANCE" или DATA_TYPE = single , надо здесь завести счетчик, для переключения в SEND_DATA 
                end
            SEND_DATA:
                begin
                    next_state = (m_idx_tvalid && m_idx_tready) ? IDLE : SEND_DATA;
                end
            default: 
                begin
                    next_state = IDLE;
                end
        endcase
    end
    
endmodule
