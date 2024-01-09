`timescale 1ns / 1ns

//Project name: "Adaptive filter"
//Author:        Kavruk A.
//File description: Testbench

module adaptive_filter_tb (
);

    localparam FILTER_MODE       = 0; // если 0 - дифференцирование, 1 - интегрирование
    localparam INCLUDE_SDF       = 0; // включение .sdf  
    localparam SIM_EN            = 1; // включает несинтезируемую часть в RTL для тестирования

    //Параметры ширины входных/выходных данных
    localparam WORDLEGTH         = 14;
    localparam FRACTIONAL_LENGTH = 6;

    //Параметры чтения данных модели
    localparam DATA_NUM         = 128;
    localparam DATA_DIR         = "C:\\MyFolder\\RemoteFolder\\projects\\adaptive_filter\\Source\\tbn\\data\\";

    //Чтение/запись входного/выходного воздействия
    localparam INPUT_FILE_NAME  = "data_in.txt";
    localparam OUTPUT_FILE_NAME = "data_out.txt";
    localparam MODEL_FILE_NAME  = "model_data_differentiator.txt";


    logic clk;
    logic srst;

    //Входные сигналы
    logic [WORDLEGTH-1:0] s_tdata;
    logic                 s_tvalid;
    logic [WORDLEGTH-1:0] s_tdata_mem [DATA_NUM-1:0];

    //Выходные сигналы
    logic [WORDLEGTH-1:0] m_tdata;
    logic [WORDLEGTH-1:0] m_tdata_mem [DATA_NUM-1:0];
    logic                 m_tvalid;
    
    logic [WORDLEGTH-1:0] model_valid_tdata [DATA_NUM-1:0];

    //Вспомогательные сигналы для проверки выходныз данных
    logic                 start_display;
    logic                 output_is_valid_to_model; 
    logic                 finish_data_transfer;

    always begin
        #2 clk = ~clk;
    end

    initial begin
        if (INCLUDE_SDF) begin
            $sdf_annotate("../Outputs/Place_and_route/adaptive_filter.sdf", dut);    
        end

        //Инициализация модуля
        clk  = 1;
        srst = 1;
        #10;
        srst = 0;

        //Чтение файлов модели и входного воздействия
        $readmemb({DATA_DIR, INPUT_FILE_NAME}, s_tdata_mem);
	    $readmemb({DATA_DIR, MODEL_FILE_NAME}, model_valid_tdata);
    end

    //Объявление модуля
    adaptive_filter #(
        .SIM_EN   (SIM_EN     )
        ) dut (
        .clk      (clk        ),
        .srst     (srst       ),
        .ctrl     (FILTER_MODE),

        .s_tdata  (s_tdata    ),
        .s_tvalid (s_tvalid   ),

        .m_tdata  (m_tdata    ),
        .m_tvalid (m_tvalid   )
    );

    //Счечики контроля входного потока данных и выходных данных фильтра
    logic [$clog2(DATA_NUM)-1:0] cnt_output_data;
    logic [$clog2(DATA_NUM)-1:0] cnt_input_data;

    //Защелкивание данных входного воздействия + управление счетчиками контроля симуляции
    always_ff @(posedge clk) begin
        if (srst) begin
            foreach (m_tdata_mem[element]) begin
                m_tdata_mem[element] <= '0;
            end

            s_tdata                  <= '0;
            cnt_output_data          <= '0;
            cnt_input_data           <= '0;
            finish_data_transfer     <= '0;
            s_tvalid                 <= 1'b0;
        end else begin
            s_tvalid                     <= 1'b1;
            s_tdata                      <= s_tdata_mem[cnt_input_data];
            cnt_input_data               <= cnt_input_data + 1;
            m_tdata_mem[cnt_output_data] <= m_tdata;
            cnt_output_data              <= (m_tvalid) ? cnt_output_data + 1 : cnt_output_data;
            finish_data_transfer         <= (cnt_output_data == (DATA_NUM - 1)) ? 1'b1 : finish_data_transfer;;
        end
    end

    //Вывод в консоль результата проверки и остановка симуляции
    assign output_is_valid_to_model = model_valid_tdata[cnt_output_data] == m_tdata;
    assign start_display            = m_tvalid;
    always_ff @(posedge clk) begin
        if (start_display && !finish_data_transfer) begin
            if (output_is_valid_to_model) begin
                $display("Sample %d: PASS",cnt_output_data);
            end else begin
                $display("Sample %d: FAIL",cnt_output_data);
            end
        end

        if ((cnt_output_data == 0) && finish_data_transfer) begin
            $writememb({DATA_DIR, OUTPUT_FILE_NAME}, m_tdata_mem);
            $finish();           
        end
    end

endmodule : adaptive_filter_tb
