`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/15/2023 01:55:37 PM
// Design Name: 
// Module Name: binary_search_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module binary_search_tb();

    localparam SIM_EN          = 1;
    localparam DATA_TYPE       = "fixed";
    localparam DATA_WIDTH      = 16;
    localparam CODEBOOK_LENGTH = 16'd1000;
    localparam RAM_TYPE        = "LOW_LATENCY";
    localparam ALPHA_FILE      = "/home/ubuntu/Projects/RSA/Quantizer/alpha.mif";

    logic                  clk_i;
    logic                  srst_i;

    logic [DATA_WIDTH-1:0] s_alpha_tdata;
    logic                  s_alpha_tvalid;
    logic                  s_alpha_tready;

    logic [DATA_WIDTH-1:0] m_idx_tdata;
    logic                  m_idx_tvalid;

    always begin
       #2 clk_i = ~clk_i;
    end

    initial begin
        clk_i  = 0;
        srst_i = 1;
        #20;
        srst_i = 0;
        s_alpha_tdata  = 16'd736;
        s_alpha_tvalid = 1'b1;
        #10;
        s_alpha_tdata  = 0;
        s_alpha_tvalid = 1'b0;
        #180;
        s_alpha_tdata  = 16'd431;
        s_alpha_tvalid = 1'b1;
        #10;
        s_alpha_tdata  = 0;
        s_alpha_tvalid = 1'b0;
    end

    binary_search #(
        .SIM_EN          (0              ),
        .DATA_TYPE       (DATA_TYPE      ),
        .DATA_WIDTH      (DATA_WIDTH     ),
        .CODEBOOK_LENGTH (CODEBOOK_LENGTH),
        .RAM_TYPE        (RAM_TYPE       ),
        .ALPHA_FILE      (ALPHA_FILE     )
    ) dut (
        .clk_i            (clk_i         ),
        .srst_i           (srst_i        ),
        .s_alpha_tdata    (s_alpha_tdata ),
        .s_alpha_tvalid   (s_alpha_tvalid),
        .s_alpha_tready   (s_alpha_tready),
        .m_idx_tdata      (m_idx_tdata   ),
        .m_idx_tvalid     (m_idx_tvalid  ),
        .m_idx_tready     (1'b1          )
    );

endmodule
