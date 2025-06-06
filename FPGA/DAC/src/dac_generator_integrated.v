// DAC波形发生器 - 基于13位地址ROM的14位DAC控制器
`define SYSTEM_CLK         125000000     // 系统时钟频率(Hz)
`define DAC_BITS           14            // DAC分辨率
`define PHASE_ADDR_BITS    12            // 相位地址位宽
`define DEFAULT_CENTER     (2**(`DAC_BITS-1)) // 波形中心点值

// 第一路波形 (MHz级)
`define FREQ_CTRL_1_MHZ 32'd343597383 // 10.00MHz@125.00MHz时钟
`define FREQ_STEP_1_MHZ 32'd68719476  // 2.00MHz步进@125.00MHz时钟
`define FREQ_MAX_1_LIMIT 32'd1374389534 // 40.00MHz最大值

// 第二路波形 (kHz级)
`define FREQ_CTRL_2_KHZ 32'd3435973 // 100.00kHz@125.00MHz时钟
`define FREQ_STEP_2_KHZ 32'd3435973  // 100.00kHz步进@125.00MHz时钟
`define FREQ_MAX_2_LIMIT 32'd34359738 // 1000.00kHz最大值

// 波形选择编码
`define WAVE_SINE          3'b110        // 正弦波
`define WAVE_TRIANGLE      3'b101        // 三角波
`define WAVE_SQUARE        3'b011        // 方波

module dac_generator_integrated (
    input         sys_clk,       // 外部输入时钟
    input         rst,          // 系统复位，低电平复位
    input         key_in1,      // 调制信号频率调节按键
    input         key_in2,      // 载波信号频率调节按键
    // input  [2:0]  wave_sel1, // 调制选择开关
    // input  [2:0]  wave_sel2, // 载波选择开关
    // output [13:0] dac_out1,     // 调制信号DAC数据输出
    // output [13:0] dac_out2,     // 载波DAC数据输出
    output        dac_clk1,     // DAC时钟1
    // output        dac_clk2,     // DAC时钟2
    output [13:0] am_out        // 调制信号DAC数据输出
);

    //===================================================
    // 内部信号定义
    //===================================================
    // 时钟和复位相关
    wire        dac_clk;            // 系统时钟
    wire [2:0]  wave_sel1 = `WAVE_SINE; // 默认选择正弦波
    wire [2:0]  wave_sel2 = `WAVE_SINE; // 默认选择正弦波
    
    // 频率控制相关
    reg  [31:0] freq_ctrl1;      // 调制信号频率控制字
    reg  [31:0] freq_ctrl2;      // 载波信号频率控制字
    reg         key_in1_r1;      // 按键1输入寄存器
    reg         key_in1_r2;      // 按键1输入寄存器
    reg         key_in2_r1;      // 按键2输入寄存器
    reg         key_in2_r2;      // 按键2输入寄存器
    wire        key_pos1  ;      // 去抖后的按键1信号
    wire        key_pos2  ;      // 去抖后的按键2信号
    
    // 相位累加器相关
    reg  [31:0] phase_acc1;      // 相位累加器1
    reg  [31:0] phase_acc2;      // 相位累加器2
    wire [`PHASE_ADDR_BITS-1:0] phase_addr1; // 相位地址1
    wire [`PHASE_ADDR_BITS-1:0] phase_addr2; // 相位地址2
    
    // 波形数据相关
    wire [`DAC_BITS-1:0] sin_data1;       // 正弦波数据1
    wire [`DAC_BITS-1:0] sin_data2;       // 正弦波数据2
    reg  [`DAC_BITS-1:0] tri_data1;       // 三角波数据1
    reg  [`DAC_BITS-1:0] tri_data2;       // 三角波数据2
    reg  [`DAC_BITS-1:0] sqr_data1;       // 方波数据1
    reg  [`DAC_BITS-1:0] sqr_data2;       // 方波数据2
    reg  [`DAC_BITS-1:0] dac_data_reg1;   // DAC数据寄存器1
    reg  [`DAC_BITS-1:0] dac_data_reg2;   // DAC数据寄存器2
    wire  [2*`DAC_BITS-1:0] am_out_wire;  // am输出寄存器
    reg   [2*`DAC_BITS-1:0] am_out_reg1;   // am输出寄存器
    reg   [`DAC_BITS-1:0] am_out_reg2;   // am输出寄存器
    wire                 pll_locked;     // PLL锁定状态指示1
    
    // 系统复位信号 (PLL锁定后才释放) - 高电平复位
    assign dac_clk1 = dac_clk; // DAC时钟输出直接连接到系统时钟
    // assign dac_clk2 = dac_clk; // DAC时钟输出直接连接到系统时钟

    //===================================================
    // 按键处理集成
    //===================================================
    always @(posedge dac_clk or negedge rst) begin
        if (!rst)begin
            key_in1_r1 <= 1'b1;
            key_in1_r2 <= 1'b1;
        end else begin
            key_in1_r1 <= key_in1; // 采样按键输入
            key_in1_r2 <= key_in1_r1; // 二次采样
        end
    end
    
    always @(posedge dac_clk or negedge rst) begin
        if (!rst)begin
            key_in2_r1 <= 1'b1;
            key_in2_r2 <= 1'b1;
        end else begin
            key_in2_r1 <= key_in2; // 采样按键输入
            key_in2_r2 <= key_in2_r1; // 二次采样
        end
    end
    
    assign key_pos1 = key_in1_r1 & ~key_in1_r2; // 上升沿检测
    assign key_pos2 = key_in2_r1 & ~key_in2_r2; // 上升沿检测
    
    //===================================================
    // 频率控制
    //===================================================
    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            freq_ctrl1 <= `FREQ_CTRL_1_MHZ;  // 初始频率10MHz
        end else if (key_pos1) begin
            // 添加溢出判断 - 检查是否会超过最大限制
            if (freq_ctrl1 + `FREQ_STEP_1_MHZ > `FREQ_MAX_1_LIMIT) 
                freq_ctrl1 <= `FREQ_CTRL_1_MHZ;  // 超过最大值则回到初始值
            else
                freq_ctrl1 <= freq_ctrl1 + `FREQ_STEP_1_MHZ;  // 正常递增
        end else begin
            freq_ctrl1 <= freq_ctrl1; // 保持当前频率
        end
    end
    
    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            freq_ctrl2 <= `FREQ_CTRL_2_KHZ;  // 初始频率1KHz
        end else if (key_pos2) begin
            // 添加溢出判断 - 检查是否会超过最大限制
            if (freq_ctrl2 + `FREQ_STEP_2_KHZ > `FREQ_MAX_2_LIMIT)
                freq_ctrl2 <= `FREQ_CTRL_2_KHZ;  // 超过最大值则回到初始值
            else
                freq_ctrl2 <= freq_ctrl2 + `FREQ_STEP_2_KHZ;  // 正常递增
        end else begin
            freq_ctrl2 <= freq_ctrl2; // 保持当前频率
        end
    end
    //===================================================
    // 相位累加器集成
    //===================================================
    // 原add_32bit模块功能集成
    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            phase_acc1 <= 32'd0;
        end else begin
            phase_acc1 <= phase_acc1 + freq_ctrl1;
        end
    end

    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            phase_acc2 <= 32'd0;
        end else begin
            phase_acc2 <= phase_acc2 + freq_ctrl2;
        end
    end

    // 相位地址输出 (截取高位用于波形查找)
    assign phase_addr1 = phase_acc1[31:20]; // 12位相位地址
    assign phase_addr2 = phase_acc2[31:20]; // 12位相位地址

    //===================================================
    // 三角波生成 - 14位版本（适配13位地址）
    //===================================================
    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            tri_data1 <= 14'd0;
        end else begin
            // 三角波生成 (14位, 最大值16383)
            if (phase_addr1 < 13'd4096)
                tri_data1 <= {phase_addr1[11:0], 2'b00};  // Rising from 0 to 16384
            else
                tri_data1 <= {(13'd8191 - phase_addr1), 2'b00};  // Falling from 16384 to 0
        end
    end

    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            tri_data2 <= 14'd0;
        end else begin
            // 三角波生成 (14位, 最大值16383)
            if (phase_addr2 < 13'd4096)
                tri_data2 <= {phase_addr2[11:0], 2'b00};  // Rising from 0 to 16384
            else
                tri_data2 <= {(13'd8191 - phase_addr2), 2'b00};  // Falling from 16384 to 0
        end
    end    
    
    //===================================================
    // 方波生成 - 14位版本（适配13位地址）
    //===================================================
    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            sqr_data1 <= 14'd0;
        end else begin
            // 方波生成 (14位, 最大值16383)
            sqr_data1 <= (phase_addr1 < 13'd4096) ? 14'h3FFF : 14'd0;
        end
    end    

    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            sqr_data2 <= 14'd0;
        end else begin
            // 方波生成 (14位, 最大值16383)
            sqr_data2 <= (phase_addr2 < 13'd4096) ? 14'h3FFF : 14'd0;
        end
    end

    //===================================================
    // 频率自适应振幅补偿
    //===================================================
    reg [4:0] amplitude_comp1;  // 振幅补偿系数
    reg [4:0] amplitude_comp2;  // 振幅补偿系数

    // 根据频率控制字计算补偿系数 - 5MHz步进精度
    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            amplitude_comp1 <= 5'd10;  // 默认补偿系数 (1.0x)
        end else begin
            // 频率越高，补偿系数越大，10MHz为基准(1.0x)
            if (freq_ctrl1 < 32'd343597383)      // 7.5-10MHz
                amplitude_comp1 <= 5'd10;         // 1.0x (10MHz基准点)
            else if (freq_ctrl1 < 32'd515396075)      // 10-15MHz
                amplitude_comp1 <= 5'd11;         // 1.1x
            else if (freq_ctrl1 < 32'd687194767)      // 15-20MHz
                amplitude_comp1 <= 5'd12;         // 1.2x
            else if (freq_ctrl1 < 32'd858993459)      // 20-25MHz
                amplitude_comp1 <= 5'd13;         // 1.3x
            else if (freq_ctrl1 < 32'd1030792150)     // 25-30MHz
                amplitude_comp1 <= 5'd14;         // 1.4x
            else if (freq_ctrl1 < 32'd1202590842)     // 30-35MHz
                amplitude_comp1 <= 5'd15;         // 1.5x
            else if (freq_ctrl1 < 32'd1374389534)     // 35-40MHz
                amplitude_comp1 <= 5'd16;         // 1.6x
            else                                     // > 40MHz
                amplitude_comp1 <= 5'd17;         // 1.7x
        end
    end

// 修改第二路波形的增益补偿逻辑 - 扩展到MHz级别
    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            amplitude_comp2 <= 5'd10;  // 默认补偿系数 (1.0x)
        end else begin
            // 根据频率控制字调整振幅补偿 - 范围从100kHz到1MHz
            // 频率越高，补偿系数越大，100kHz为基准(1.0x)
            if (freq_ctrl2 < 32'd6871946)              // 100-200kHz
                amplitude_comp2 <= 5'd10;          // 1.0x (100kHz基准点)
            else if (freq_ctrl2 < 32'd10307919)        // 200-300kHz
                amplitude_comp2 <= 5'd11;          // 1.1x
            else if (freq_ctrl2 < 32'd13743892)        // 300-400kHz
                amplitude_comp2 <= 5'd12;          // 1.2x
            else if (freq_ctrl2 < 32'd17179865)        // 400-500kHz
                amplitude_comp2 <= 5'd13;          // 1.3x
            else if (freq_ctrl2 < 32'd20615838)        // 500-600kHz
                amplitude_comp2 <= 5'd14;          // 1.4x
            else if (freq_ctrl2 < 32'd24051811)        // 600-700kHz
                amplitude_comp2 <= 5'd15;          // 1.5x
            else if (freq_ctrl2 < 32'd27487784)        // 700-800kHz
                amplitude_comp2 <= 5'd16;          // 1.6x
            else if (freq_ctrl2 < 32'd30923757)        // 800-900kHz
                amplitude_comp2 <= 5'd17;          // 1.7x
            else if (freq_ctrl2 < 32'd34359738)        // 900kHz-1MHz
                amplitude_comp2 <= 5'd18;          // 1.8x
            else                                        // > 1MHz
                amplitude_comp2 <= 5'd19;          // 1.9x
        end
    end
    // 应用振幅补偿
    reg [32:0] sin_comp_mult1_reg;
    reg [32:0] sin_comp_mult2_reg;
    reg [13:0] sin_compensated1_reg; // 限制在14位范围内
    reg [13:0] sin_compensated2_reg; // 限制在14位范围内
    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            sin_comp_mult1_reg <= 0;
            sin_comp_mult2_reg <= 0;
        end else begin
            sin_comp_mult1_reg <= sin_data1 * amplitude_comp1;
            sin_comp_mult2_reg <= sin_data2 * amplitude_comp2;
        end
    end

    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            sin_compensated1_reg <= 0;
            sin_compensated2_reg <= 0;
        end else begin
            if (sin_comp_mult1_reg / 10 > 14'h3FFF) begin
                sin_compensated1_reg <= 14'h3FFF;
            end else if (sin_comp_mult1_reg / 10 < 14'h8) begin
                sin_compensated1_reg <= 14'h8; // 最小值限制
            end else begin
                sin_compensated1_reg <= sin_comp_mult1_reg / 10;
            end
            
            if (sin_comp_mult2_reg / 10 > 14'h3FFF) begin
                sin_compensated2_reg <= 14'h3FFF;
            end else if (sin_comp_mult2_reg / 10 < 14'h8) begin
                sin_compensated2_reg <= 14'h8; // 最小值限制
            end else begin
                sin_compensated2_reg <= sin_comp_mult2_reg / 10;
            end
        end
    end
    //===================================================
    // 波形选择集成 - 使用滤波后的正弦波
    //===================================================
    // 原sel_wave模块功能集成
    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            dac_data_reg1 <= 14'd0;
        end else begin
            case (wave_sel1)
                3'b110 : dac_data_reg1 <= sin_compensated1_reg;
                3'b101 : dac_data_reg1 <= tri_data1;
                3'b011 : dac_data_reg1 <= sqr_data1;
                default : dac_data_reg1 <= sin_compensated1_reg;
            endcase
        end
    end
    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            dac_data_reg2 <= 14'd0;
        end else begin
            case (wave_sel2)
                3'b110 : dac_data_reg2 <= sin_compensated2_reg;
                3'b101 : dac_data_reg2 <= tri_data2;
                3'b011 : dac_data_reg2 <= sqr_data2;
                default : dac_data_reg2 <= sin_compensated2_reg;
            endcase
        end
    end
    //===================================================
    // 输出缓冲寄存器 - 添加额外的寄存级别
    //===================================================
    reg [13:0] dac_out_reg1;
    reg [13:0] dac_out_reg2;

    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            dac_out_reg1 <= 14'd0;
        end else begin
            dac_out_reg1 <= dac_data_reg1;
        end
    end
    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            dac_out_reg2 <= 14'd0;
        end else begin
            dac_out_reg2 <= dac_data_reg2;
        end
    end
    // 输出赋值
    // assign dac_out1 = dac_out_reg1;
    // assign dac_out2 = dac_out_reg2;

    //===================================================
    // AM调制输出寄存器
    //===================================================
    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            am_out_reg1 <= 28'd0;
        end else begin
            am_out_reg1 <= am_out_wire;
        end
    end

    always @(posedge dac_clk or negedge rst) begin
        if (!rst) begin
            am_out_reg2 <= 14'd0;
        end else begin
            // AM调制输出 - 使用乘法器计算
            am_out_reg2 <= (am_out_reg1[2*`DAC_BITS-1:`DAC_BITS] > 14'h3FFF) ? 14'h3FFF : am_out_reg1[2*`DAC_BITS-1:`DAC_BITS] ; // 直接使用14位数据
        end
    end
    assign am_out = am_out_reg2 + 14'd8192;
    //===================================================
    // PLL模块内联
    //===================================================
    // 原PLLM模块功能集成
    clk_double clk_double_inst (
        .clk_in1(sys_clk),
        .resetn(rst),            // 
        .clk_out1(dac_clk),         // 系统时钟
        .locked(pll_locked)
    );

    //===================================================
    // 正弦波ROM集成 - 直接使用14位输出
    //===================================================
    sin_rom sin_rom_inst (
        .addra(phase_addr1),
        .clka(dac_clk),
        .douta(sin_data1)        // 直接连接14位输出
    );
    Carry_rom Carry_rom_inst (
        .addra(phase_addr2),
        .clka(dac_clk),
        .douta(sin_data2)        // 直接连接14位输出
    );

    //===================================================
    // AM调制器集成 - 使用乘法器
    //===================================================
    AM_Mulpliter AM_Mupliter_inst (
        .CLK(dac_clk),
        .A(dac_out_reg1-14'd8192),
        .B(dac_out_reg2-14'd8192),
        .P(am_out_wire)
    );

endmodule