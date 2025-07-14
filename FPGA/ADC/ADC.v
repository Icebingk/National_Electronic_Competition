module ADC(
    input wire          sys_clk,            // 系统时钟
    input wire          rst_n,              // 复位信号，低有效

    input wire          adc_clk,            // ADC时钟

    input wire          OTR,                // 超量程提示
    input wire [11:0]   adc_data_in,        // ADC数据输入

    output wire[11:0]   adc_data_out,       // ADC数据输出
    output wire         adc_data_ready      // ADC数据有效标志
);

wire wr_en; // 写使能信号
wire full; // FIFO满标志
wire rd_en; // 读使能信号
wire empty; // FIFO空标志

wire [11:0] adc_data; // ADC数据输出寄存器

assign adc_data_out = empty?12'd0:adc_data; // 将FIFO输出数据赋值给adc_data_out

assign wr_en = !full & !OTR; // 当FIFO未满且未超量程时允许写入
assign rd_en = !empty; // 当FIFO不为空时允许读取
assign adc_data_ready = !empty; // 当FIFO不为空时数据有效

fifo_generator_0 fifo_generator_0_inst (
    .rst(!rst_n),           // 复位信号

    .wr_clk(adc_clk),       // 写时钟
    .din(adc_data_in),      // 输入数据
    .wr_en(wr_en),          // 写使能
    .full(full),            // FIFO满标志
    
    .rd_clk(sys_clk),       // 读时钟
    .rd_en(rd_en),          // 读使能
    .dout(adc_data),        // 输出数据
    .empty(empty)           // FIFO空标志
);

endmodule
