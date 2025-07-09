// DAC波形发生器 - 基于13位地址ROM的14位DAC控制器
`define SYSTEM_CLK         125000000     // 系统时钟频率(Hz)
`define DAC_BITS           14            // DAC分辨率
`define PHASE_ADDR_BITS    13            // 相位地址位宽
`define DEFAULT_CENTER     (2**(`DAC_BITS-1)) // 波形中心点值

// 频率控制相关宏定义
`define FREQ_CTRL_MHZ 32'd343597383 // 10.00MHz@125.00MHz时钟
`define FREQ_STEP_MHZ 32'd68719476  // 2.00MHz步进@125.00MHz时钟

// 波形选择编码
`define WAVE_SINE          3'b110        // 正弦波
`define WAVE_TRIANGLE      3'b101        // 三角波
`define WAVE_SQUARE        3'b011        // 方波

module dac_generator_integrated (
    input         clk_in,      // 外部输入时钟
    input         rst,         // 系统复位，高电平复位
    input         key_in,      // 频率调节按键
    // input  [2:0]  wave_sel,    // 波形选择开关
    input  [11:0]
     data_in,     // 数据输入
    output [13:0] dac_out,     // DAC数据输出
    output        dac_clk      // DAC时钟
    // output        pll_locked   // PLL锁定状态指示
);

    //===================================================
    // 内部信号定义
    //===================================================
    // 时钟和复位相关
    wire        clk;            // 系统时钟
    wire [2:0]  wave_sel = `WAVE_SINE; // 默认选择正弦波
    
    // 频率控制相关
    reg  [31:0] freq_ctrl;      // 频率控制字
    reg         key_in_r1;      // 按键输入寄存器
    reg         key_in_r2;      // 按键输入寄存器
    wire        key_pos  ;      // 去抖后的按键信号
    
    // 相位累加器相关
    reg  [31:0] phase_acc;      // 相位累加器
    wire [`PHASE_ADDR_BITS-1:0] phase_addr; // 相位地址
    
    // 波形数据相关
    wire [`DAC_BITS-1:0] sin_data;       // 正弦波数据
    reg  [`DAC_BITS-1:0] tri_data;       // 三角波数据
    reg  [`DAC_BITS-1:0] sqr_data;       // 方波数据
    reg  [`DAC_BITS-1:0] dac_data_reg;   // DAC数据寄存器
    wire                 pll_locked;     // PLL锁定状态指示
    
    // 系统复位信号 (PLL锁定后才释放) - 高电平复位
    wire sys_rst = rst | !pll_locked;
    
    //===================================================
    // 按键处理集成
    //===================================================
    always @(posedge clk or posedge sys_rst) begin
        if (sys_rst)begin
            key_in_r1 <= 1'b1;
            key_in_r2 <= 1'b1;
        end else begin
            key_in_r1 <= key_in; // 采样按键输入
            key_in_r2 <= key_in_r1; // 二次采样
        end
    end

    assign key_pos = key_in_r1 & ~key_in_r2; // 上升沿检测

    // 频率控制
    always @(posedge clk or posedge sys_rst) begin
        if (sys_rst) begin
            freq_ctrl <= `FREQ_CTRL_MHZ;  // 初始频率10MHz
        end else if (key_pos) begin
            freq_ctrl <= freq_ctrl + `FREQ_STEP_MHZ;  // 每次增加约2MHz
        end else begin
            freq_ctrl <= freq_ctrl; // 保持当前频率
        end
    end
    
    //===================================================
    // 相位累加器集成
    //===================================================
    // 原add_32bit模块功能集成
    always @(posedge clk or posedge sys_rst) begin
        if (sys_rst) begin
            phase_acc <= 32'd0;
        end else begin
            phase_acc <= phase_acc + freq_ctrl;
        end
    end

    // 相位地址输出 (截取高位用于波形查找)
    assign phase_addr = phase_acc[31:19]; // 13位相位地址

    //===================================================
    // 三角波生成 - 14位版本（适配13位地址）
    //===================================================
    always @(posedge clk or posedge sys_rst) begin
        if (sys_rst) begin
            tri_data <= 14'd0;
        end else begin
            // 三角波生成 (14位, 最大值16383)
            if (phase_addr < 13'd4096)
                tri_data <= {phase_addr[11:0], 2'b00};  // Rising from 0 to 16384
            else
                tri_data <= {(13'd8191 - phase_addr), 2'b00};  // Falling from 16384 to 0
        end
    end

    //===================================================
    // 方波生成 - 14位版本（适配13位地址）
    //===================================================
    always @(posedge clk or posedge sys_rst) begin
        if (sys_rst) begin
            sqr_data <= 14'd0;
        end else begin
            // 方波生成 (14位, 最大值16383)
            sqr_data <= (phase_addr < 13'd4096) ? 14'h3FFF : 14'd0;
        end
    end    

    //===================================================
    // 频率自适应振幅补偿
    //===================================================
    reg [17:0] amplitude_comp;  // 振幅补偿系数

    // 根据频率控制字计算补偿系数 - 5MHz步进精度
    always @(posedge clk or posedge sys_rst) begin
        if (sys_rst) begin
            amplitude_comp <= 14'd10;  // 默认补偿系数 (1.0x)
        end else begin
            // 根据频率控制字调整振幅补偿 - 精细分段
            // 频率越高，补偿系数越大
            if (freq_ctrl < 32'd171798692)           // < 5MHz
                amplitude_comp <= 14'd10;         // 1.0x
            else if (freq_ctrl < 32'd343597383)      // 5-10MHz
                amplitude_comp <= 14'd11;         // 1.1x
            else if (freq_ctrl < 32'd515396075)      // 10-15MHz
                amplitude_comp <= 14'd12;         // 1.2x
            else if (freq_ctrl < 32'd687194767)      // 15-20MHz
                amplitude_comp <= 14'd13;         // 1.3x
            else if (freq_ctrl < 32'd858993459)      // 20-25MHz
                amplitude_comp <= 14'd14;         // 1.4x
            else if (freq_ctrl < 32'd1030792150)     // 25-30MHz
                amplitude_comp <= 14'd15;         // 1.5x
            else if (freq_ctrl < 32'd1202590842)     // 30-35MHz
                amplitude_comp <= 14'd16;         // 1.6x
            else if (freq_ctrl < 32'd1374389534)     // 35-40MHz
                amplitude_comp <= 14'd17;         // 1.7x
            else if (freq_ctrl < 32'd1546188226)     // 40-45MHz
                amplitude_comp <= 14'd18;         // 1.8x
            else if (freq_ctrl < 32'd1717986918)     // 45-50MHz
                amplitude_comp <= 14'd19;         // 1.9x
            else                                     // > 50MHz
                amplitude_comp <= 14'd20;         // 2.0x
        end
    end
    // 应用振幅补偿
    wire [32:0] sin_comp_mult = sin_data * amplitude_comp;
    wire [13:0] sin_compensated = (sin_comp_mult / 10) > 14'h3FFF ? 14'h3FFF : sin_comp_mult / 10; // 限制在14位范围内

    //===================================================
    // 波形选择集成 - 使用滤波后的正弦波
    //===================================================
    // 原sel_wave模块功能集成
    always @(posedge clk or posedge sys_rst) begin
        if (sys_rst) begin
            dac_data_reg <= 14'd0;
        end else begin
            case (wave_sel)
                3'b110 : dac_data_reg <= sin_compensated; // 使用滤波后的正弦波
                3'b101 : dac_data_reg <= tri_data;
                3'b011 : dac_data_reg <= sqr_data;
                default : dac_data_reg <= sin_compensated;
            endcase
        end
    end

    //===================================================
    // 输出缓冲寄存器 - 添加额外的寄存级别
    //===================================================
    reg [13:0] dac_out_reg;

    always @(posedge clk or posedge sys_rst) begin
        if (sys_rst) begin
            dac_out_reg <= 14'd0;
        end else begin
            dac_out_reg <= dac_data_reg;
        end
    end

    // 输出赋值
    assign dac_out = dac_out_reg;

    //===================================================
    // PLL模块内联
    //===================================================
    // 原PLLM模块功能集成
    clk_double PLLM_inst (
        .clk_in1(clk_in),
        .reset(rst),            // 高电平复位，直接连接
        .clk_out1(clk),         // 系统时钟
        .clk_out2(dac_clk),     // DAC时钟
        .locked(pll_locked)
    );

    //===================================================
    // 正弦波ROM集成 - 直接使用14位输出
    //===================================================
    sin_rom sin_rom_inst (
        .addra(phase_addr),
        .clka(clk),
        .douta(sin_data)        // 直接连接14位输出
    );
    
endmodule