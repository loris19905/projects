`timescale 1ns / 1ns


  /*
  * Title        : Потоковый ресайзер
  * File         : stream_resizer.sv
  * Description  : Реализация изменения входной длины пакета данных. Интерфейс данных - AXI4-Stream.
  */


module stream_rescale 
    #(
    parameter T_DATA_WIDTH = 4,
    parameter S_KEEP_WIDTH = 4,
    parameter M_KEEP_WIDTH = 2
    )(
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic [T_DATA_WIDTH-1:0] s_data_i [S_KEEP_WIDTH-1:0],
    input  logic [S_KEEP_WIDTH-1:0] s_keep_i,
    input  logic                    s_tlast_i,
    input  logic                    s_valid_i,
    output logic                    s_ready_o,

    output logic [T_DATA_WIDTH-1:0] m_data_o [M_KEEP_WIDTH],
    output logic [M_KEEP_WIDTH-1:0] m_keep_o,
    output logic                    m_tlast_o,
    output logic                    m_valid_o,
    input  logic                    m_ready_i      
    );

    //Входная транзакция больше выходной:
    //по сути размер буфера влияет только на то, как часто мы будем переполняться (больше буфер, меньше вероятность)
    //стратегия такая: если значение addr_write - addr_read_reg > BUFFER_SIZE - S_KEEP_WIDTH (по принципу fifo), то сигнал tready_o выставляется равным 0, если
    //наоборот s_ready_o = 1'b1.

    //Выходная транзакция больше входной:
    //здесь будто бы буфер может понадобиться, если например на выходе не выставлен сигнал s_ready_o, и надо складировать 
    //данные в каком-то буфере; 

    //в обоих случаях размер буфера должен как минимум быть равен наибольшей ширине входной/выходной шины 

    //пока что делаю без s_tlast_i

    localparam MAGIC_COEFF = 4;
    localparam BUFFER_SIZE = (S_KEEP_WIDTH >= M_KEEP_WIDTH) ? MAGIC_COEFF * S_KEEP_WIDTH : MAGIC_COEFF * M_KEEP_WIDTH;  

    logic [T_DATA_WIDTH-1:0] buffer_reg [2*S_KEEP_WIDTH-1:0];

    logic [$clog2(BUFFER_SIZE)-1:0]  addr_write;
    logic [$clog2(BUFFER_SIZE)-1:0]  addr_write_reg;
    logic [$clog2(BUFFER_SIZE)-1:0]  addr_read;
    logic [$clog2(BUFFER_SIZE)-1:0]  addr_read_reg;
    logic [$clog2(S_KEEP_WIDTH)-1:0] cnt_keep;
    logic [$clog2(S_KEEP_WIDTH)-1:0] cnt_avl;

    //производится защелкивание валидных данных по входу по сигналу handshake = s_valid_i && s_ready_o
    //тут вроде тоже все ок
    always_ff @(posedge clk) begin
      if (~rst_n) begin
        buffer_reg     <= 0;
        addr_write_reg <= 0;
        s_ready_o      <= 0;
      end else begin
        if (s_valid_i && s_ready_o) begin
          for (int i = addr_write_reg; i < addr_write; i++) begin
            if (s_keep_i[i - addr_write_reg]) begin
              buffer_reg[i] <= s_data_i[i - addr_write_reg];
            end 
          end
        end else begin
          buffer_reg <= buffer_reg;
        end
        addr_write_reg <= addr_write;
      end
    end

    //подсчитывается адрес, начиная с которого будут записаны данные
    //в следующий раз
    //тут все логично
    always_comb begin
      if (s_valid_i) begin
        for(int i = 0; i < S_KEEP_WIDTH; i++) begin
          cnt_keep = (s_keep_i[i]) ? cnt_keep + 1 : cnt_keep;    
        end
      end else begin
        cnt_keep = 0;
      end
      addr_write = addr_write_reg + cnt_keep;
      s_ready_o  = ((addr_write - addr_read_reg) == BUFFER_SIZE) ? 1'b0 : 1'b1;  
    end

    //Отправка данных на выход, ожидание handshake (адрес чтения не меняется, сигнал валидности удерживается)

    always_ff @(posedge clk) begin
      if (~rst_n) begin
        m_tvalid_o    <= 0;
        m_data_o      <= 0;
        m_keep_o      <= 0;
        addr_read_reg <= 0;
      end else begin
        if (tvalid_comb_o) begin
            for (int i = 0; i < M_KEEP_WIDTH; i++) begin
              if (i < cnt_avl) begin
                m_data_o[i] <= buffer_reg[addr_read_reg + i];
                m_keep_o[i] <= 1'b1;  
              end else begin
                m_data_o[i] <= 0;
                m_keep_o[i] <= 1'b0;
              end
            end
        end else begin
          m_data_o <= m_data_o;
          m_keep_o <= 0;
        end
        addr_read_reg <= (m_tvalid_o && m_ready_i) ? addr_read : addr_read_reg;
        m_tvalid_o    <= (m_tvalid_o && m_ready_i) ? 0 : tvalid_comb_o; //  условие для сброса tvalid, если произошел handshake
      end
    end

    //Подсчет смещения адреса чтения (по сути просто инкремент на величину размера буфера с учетом количества валидных данных)
    logic tvalid_comb_o;
    always_comb begin
      cnt_avl       = ((addr_write_reg - addr_read_reg) >= M_KEEP_WIDTH) ? M_KEEP_WIDTH : addr_write_reg - addr_read_reg;
      addr_read     = addr_read_reg + cnt_avl;
      tvalid_comb_o = (cnt_avl == 0) ? 1'b0 : 1'b1;
    end
   
endmodule