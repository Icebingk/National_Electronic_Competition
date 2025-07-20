module top (
    input wire          clk_in,    // 系统时钟
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
wire signed [11:0] adc_data_out;
wire adc_data_ready;
wire data_ready;
wire signed[13:0] data_out;
wire  [13:0] data_out_wire;
wire sys_clk;
reg enable;
wire coeff_load_over;

assign data_out_wire = data_out + 14'd8192; // 将FIR输出数据连接到DAC输入，转化为无符号数

always@(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        enable <= 1'b0; // 初始状态为禁用
    end else if (coeff_load_over) begin
        enable <= 1'b1; // 启用模块
    end else begin
        enable <= enable; // 保持当前状态
    end
end

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
    .data_out(data_out),
    .enable(enable),
    .coeff_load_over(coeff_load_over)
);

DAC_Generate  DAC_Generate_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .dac_clk(clk_dac),
    .default_mode(1'b0),
    .dac_data_in_valid(data_ready),
    .dac_data_in(data_out_wire),
    .dac_out(dac_data)
  );

clk_wiz_0  clk_wiz_0_inst (
    .clk_out1(clk_adc),
    .clk_out2(sys_clk),
    .clk_out3(clk_dac),
    .reset(!rst_n),
    .locked(locked),
    .clk_in1(clk_in)
  );
endmodule