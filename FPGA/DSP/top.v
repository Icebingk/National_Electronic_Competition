// ADC9226模块的驱动程序 - 使用各自时钟域的设计
module top (
    input wire          sys_clk_p, // 差分系统时钟P
    input wire          sys_clk_n, // 差分系统时钟N
    input wire          rst_n,     // 复位信号，低有效
    input wire          key,       // 按键信号
    input wire [11:0]   adc_data,  // ADC输入数据
    output reg [13:0]   data_out,  // DAC输出数据
    output wire         adc_clk,   // ADC时钟输出
    output wire         sys_clk,   // 系统时钟输出
    output wire         dac_clk    // DAC时钟输出
);

// 系统时钟和PLL生成
wire locked;

// FIR滤波器相关
wire [49:0] fir_data_out;
wire data_ready;
reg [11:0] fir_input_data;

// 按键和模式控制
reg key_reg1, key_reg2;
wire posedge_key;
reg flag;

// ADC时钟域寄存器
reg [11:0] adc_data_adc;   // 在ADC时钟域采样的数据

// DAC时钟域同步寄存器
reg [11:0] adc_data_dac1, adc_data_dac2;  // 同步到DAC时钟域的寄存器

// 差分时钟转单端
IBUFDS IBUFDS_inst (
    .O(sys_clk),
    .I(sys_clk_p),
    .IB(sys_clk_n)
);
    
// 时钟生成
clk_wiz_0 clk_wiz_0_inst (
    .clk_out1(dac_clk), // ADC 65MHz
    .clk_out2(adc_clk), // DAC 125MHz (用作主时钟)
    .locked(locked),
    .clk_in1(sys_clk)
);

// 按键信号边沿检测 (使用dac_clk)
always @(posedge dac_clk or negedge rst_n) begin
    if (!rst_n) begin
        key_reg1 <= 1'b0;
        key_reg2 <= 1'b0;
    end else begin
        key_reg1 <= key;
        key_reg2 <= key_reg1;
    end
end
assign posedge_key = key_reg1 & ~key_reg2;

// 模式切换标志 (使用dac_clk)
always @(posedge dac_clk or negedge rst_n) begin
    if (!rst_n) begin
        flag <= 1'b0;
    end else if (posedge_key) begin
        flag <= ~flag;
    end
end

// ADC数据采样 - 使用ADC时钟域 (关键改变点)
always @(posedge adc_clk or negedge rst_n) begin
    if (!rst_n) begin
        adc_data_adc <= 12'b0;
    end else begin
        // 在ADC自己的时钟域采样数据，避免采样亚稳态
        adc_data_adc <= adc_data;
    end
end

// ADC数据同步到DAC时钟域 (由ADC时钟域传输到DAC时钟域)
always @(posedge dac_clk or negedge rst_n) begin
    if (!rst_n) begin
        adc_data_dac1 <= 12'b0;
        adc_data_dac2 <= 12'b0;
        fir_input_data <= 12'b0;
    end else begin
        // 双寄存器同步技术
        adc_data_dac1 <= adc_data_adc;   // 第一级同步
        adc_data_dac2 <= adc_data_dac1;  // 第二级同步
        fir_input_data <= adc_data_dac2; // 用于FIR处理
    end
end

// 增加采样数据有效检测信号
reg [11:0] prev_adc_data;
reg adc_data_valid;

// 检测ADC数据变化以确定是否为新采样
always @(posedge dac_clk or negedge rst_n) begin
    if (!rst_n) begin
        prev_adc_data <= 12'b0;
        adc_data_valid <= 1'b0;
    end else begin
        prev_adc_data <= adc_data_dac2;
        // 当采样数据变化时认为有新的有效数据
        if (adc_data_dac2 != prev_adc_data) begin
            adc_data_valid <= 1'b1;
        end else begin
            adc_data_valid <= 1'b0;
        end
    end
end

// FIR处理 (使用dac_clk)
FIR fir_inst (
    .clk(dac_clk),          // 使用DAC时钟处理FIR
    .rst_n(rst_n),
    .data_valid(adc_data_valid), // 仅在有新采样数据时有效
    .data_in(fir_input_data),    // 使用同步后的ADC数据
    .data_out(fir_data_out),     // FIR输出结果
    .data_ready(data_ready)      // 数据就绪信号
);

// DAC数据输出 (使用dac_clk)
always @(posedge dac_clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 14'b0;
    end else begin
        if (flag) begin
            // FIR处理模式
            if (data_ready) begin
                data_out <= fir_data_out[49:36]; // 选择合适的位宽
            end
        end else begin
            // 正确的符号位扩展
            data_out <= {{2{adc_data_dac2[11]}}, adc_data_dac2}; // 将符号位复制到高位
        end
    end
end

endmodule