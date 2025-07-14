module top_ (
    input wire          sys_clk,    // 系统时钟
    input wire          rst_n,      // 复位信号，低有效

    output wire         clk_adc,    // ADC时钟输出
    input  wire [11:0]  adc_data,   // ADC输入数据
    input  wire         OTR,    
    output wire         clk_dac,    // DAC时钟输出
    output wire [13:0]  dac_data    // DAC输出数据  
);
parameter DATA_WIDTH = 12;          // 输入数据位宽
parameter COEFF_WIDTH = 32;         // 系数量化位宽
parameter TAPS = 12;                // 滤波器抽头数
parameter OUTPUT_WIDTH = DATA_WIDTH + COEFF_WIDTH;
wire [11:0] adc_data_out;
wire adc_data_ready;
wire data_ready;
wire [13:0] data_out;

ADC  ADC_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .adc_clk(clk_adc),
    .OTR(OTR),
    .adc_data_in(adc_data),
    .adc_data_out(adc_data_out),
    .adc_data_ready(adc_data_ready)
  );

FIR # (
    .DATA_WIDTH(DATA_WIDTH),
    .COEFF_WIDTH(COEFF_WIDTH),
    .TAPS(TAPS),
    .OUTPUT_WIDTH(OUTPUT_WIDTH)
)FIR_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .data_valid(adc_data_ready),
    .data_in(adc_data_out),
    .data_ready(data_ready),
    .data_out(data_out)
);

DAC_Generate  DAC_Generate_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .dac_clk(clk_dac),
    .dac_auto_disa(1),
    .dac_data_in_valid(data_ready),
    .dac_data_in(data_out),
    .dac_out(dac_data)
  );

clk_wiz_0  clk_wiz_0_inst (
    .clk_out1(clk_adc),
    .clk_out2(clk_dac),
    .reset(!rst_n),
    .locked(locked),
    .clk_in1(sys_clk)
  );
endmodule