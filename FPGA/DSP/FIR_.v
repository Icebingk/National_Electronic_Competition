module FIR #(
    parameter DATA_WIDTH = 12,      // 输入数据位宽
    parameter COEFF_WIDTH = 32,     // 系数量化位宽
    parameter TAPS = 12,            // 滤波器抽头数
    parameter OUTPUT_WIDTH = DATA_WIDTH + COEFF_WIDTH
)(
    input  wire                             sys_clk,
    input  wire                             rst_n,
    input  wire                             data_valid,
    input  wire signed [DATA_WIDTH-1:0]     data_in,
    output reg                              data_ready,
    output reg signed [OUTPUT_WIDTH-1:0]    data_out
);
    



endmodule