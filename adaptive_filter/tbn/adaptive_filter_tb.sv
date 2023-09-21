`timescale 1ns / 1ns

  /*
  * Title        : Адаптивный фильтр (дифференциатор, интегратор)
  * File         : adaptive_filter.sv
  * Description  : Реализация адаптивного фильтра: по ctrl = 1 фильтр работает в режиме интегратора, ctrl = 0 - в режиме дифференциатор.
  */

module adaptive_filter_tb (
);

    localparam DATA_WIDTH        = 14;
    localparam WORDLEGTH         = 14;
    localparam FRACTIONAL_LENGTH = 6;

    localparam DATA_IN_LENGTH   = 128;
    localparam DATA_DIR         = "C:\\MyFolder\\RemoteFolder\\projects\\";
    localparam INPUT_FILE_NAME  = "data_in.txt";
    localparam OUTPUT_FILE_NAME = "data_out.txt";

    logic clk;
    logic srst;

    logic [WORDLEGTH-FRACTIONAL_LENGTH-1:-FRACTIONAL_LENGTH] s_tdata;
    logic [WORDLEGTH-FRACTIONAL_LENGTH-1:-FRACTIONAL_LENGTH] s_tdata_mem [DATA_IN_LENGTH-1:0];

    logic [WORDLEGTH-FRACTIONAL_LENGTH-1:-FRACTIONAL_LENGTH] m_tdata;
    logic [WORDLEGTH-FRACTIONAL_LENGTH-1:-FRACTIONAL_LENGTH] m_tdata_mem [DATA_IN_LENGTH-1:0];

    always begin
        #2 clk = ~clk;
        if (finish_data_transfer) begin
            $writememb({DATA_DIR, OUTPUT_FILE_NAME}, m_tdata_mem);
            $finish;
        end
    end

    initial begin
        clk = 0;
        srst = 1;
        #10;
        srst = 0;
        $readmemb({DATA_DIR, INPUT_FILE_NAME}, s_tdata_mem);
    end

    adaptive_filter dut (
        .clk    (clk    ),
        .srst   (srst   ),
        .ctrl   (1'b1   ),

        .s_tdata(s_tdata),
        .m_tdata(m_tdata)
    );

    logic [$clog2(DATA_IN_LENGTH)-1:0] cnt_output_data;
    logic finish_data_transfer;
    always_ff @(negedge clk) begin
        if (srst) begin
            s_tdata              <= '0;
            foreach (m_tdata_mem[element]) begin
                m_tdata_mem[element] <= '0;
            end
            cnt_output_data      <= '0;
            finish_data_transfer <= '0;
        end else begin
            s_tdata                      <= s_tdata_mem[cnt_output_data];
            m_tdata_mem[cnt_output_data] <= m_tdata;
            cnt_output_data              <= cnt_output_data + 1;
            finish_data_transfer         <= (cnt_output_data == (DATA_IN_LENGTH-1)) ? 1'b1 : finish_data_transfer;
        end
    end

endmodule : adaptive_filter_tb