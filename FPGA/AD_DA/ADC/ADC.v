/*==============================================
* Function Name  : ADC.v
* Description    : ADC模块，负责接收ADC数据并进行处理
*                   AD266输电压范围为：±5V
*                   ADC数据范围为：-2048~2047
* input port     : 
* output port    : dac_out(DAC输出数据)
* Author         : ADBD
//==============================================*/
module ADC(
    input wire                  sys_clk,            // 系统时钟
    input wire                  rst_n,              // 复位信号，低有效

    input wire                  adc_clk,            // ADC时钟

    input wire                  OTR,                // 超量程提示
    input wire        [11:0]    adc_data_in,        // ADC数据输入

    output reg signed [11:0]    adc_data_out,       // ADC数据输出
    output reg                  adc_data_ready      // ADC数据有效标志
);

wire wr_en; // 写使能信号
wire full; // FIFO满标志
wire rd_en; // 读使能信号
wire empty; // FIFO空标志

reg [11:0] adc_data_in_reg; // ADC数据输入寄存器

wire [11:0] adc_data; // ADC数据输出寄存器

assign wr_en = !full & !OTR; // 当FIFO未满且未超量程时允许写入

assign rd_en = !empty; // 当FIFO不为空时允许读取

always @(posedge adc_clk or negedge rst_n) begin
    if (!rst_n)begin
        adc_data_in_reg <= 12'd0;
    end else begin
        adc_data_in_reg <= adc_data_in;
    end
end

always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        adc_data_out <= 12'd0; // 复位时清零
        adc_data_ready <= 1'b0; // 复位时清零
    end else if (rd_en) begin
        adc_data_out <= adc_data - 12'd2048; // 进行偏移
        adc_data_ready <= 1'd1;
    end else begin
        adc_data_ready <= 1'd0;
        adc_data_out <= adc_data_out;
    end
end

fifo_generator_0 fifo_generator_0_inst (
    .rst(!rst_n),           // 复位信号

    .wr_clk(adc_clk),       // 写时钟
    .din(adc_data_in_reg),      // 输入数据
    .wr_en(wr_en),          // 写使能
    .full(full),            // FIFO满标志
    
    .rd_clk(sys_clk),       // 读时钟
    .rd_en(rd_en),          // 读使能
    .dout(adc_data),        // 输出数据
    .empty(empty)           // FIFO空标志
);

endmodule
