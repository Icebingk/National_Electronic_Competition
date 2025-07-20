module top (
    input wire          clk_in,    // 系统时钟
    input wire          rst_n,      // 复位信号，低有效
    output wire         clk_adc,    // ADC时钟输出
    input  wire [0:11]  adc_data,   // ADC输入数据
    input  wire         OTR,
    output wire         clk_dac,    // DAC时钟输出
    output wire [13:0]  dac_data    // DAC输出数据
);
    
wire signed [11:0] adc_data_out;
wire adc_data_ready;

// 在top.v中添加寄存器暂存
reg [13:0] dac_data_in;
reg        dac_data_in_valid;

wire sys_clk;
wire locked;
wire reset_n;

assign reset_n = rst_n && locked; // 确保在时钟锁定后才允许复位

always @(posedge sys_clk or negedge reset_n) begin
    if (!reset_n)begin
        dac_data_in <= 14'd0;
        dac_data_in_valid <= 1'b0;
    end else if (adc_data_ready) begin
        dac_data_in <= (adc_data_out + 12'd2048) << 2;// 
        dac_data_in_valid <= 1'b1;
    end else begin
        dac_data_in_valid <= 1'b0;
        dac_data_in <= dac_data_in;
    end
end

ADC  ADC_inst (
    .sys_clk(sys_clk),
    .rst_n(reset_n),
    .adc_clk(clk_adc),
    .OTR(OTR),
    .adc_data_in(adc_data),
    .adc_data_out(adc_data_out),//12位
    .adc_data_ready(adc_data_ready)
);

DAC_Generate  DAC_Generate_inst (
    .sys_clk(sys_clk),
    .rst_n(reset_n),
    .dac_clk(clk_dac),
    .default_mode(1'b0),
    .dac_data_in_valid(dac_data_in_valid),
    .dac_data_in(dac_data_in),
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