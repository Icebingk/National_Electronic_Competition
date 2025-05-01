// 该模块内部生成可变频率的方波信号，并且具有50%的占空比，用于驱动蜂鸣器或其他音频设备。
module buzz(
    input       wire            clk,            // 系统时钟
    input       wire            rst_n,          // 复位信号，低电平有效
    input       wire            en,             // 蜂鸣器使能信号
    input       wire [2:0]      freq_sel,       // 频率选择（8种预设频率）
    input       wire [15:0]     custom_div,     // 自定义分频值（当freq_sel=7时使用）
    output      reg             buz             // 蜂鸣器输出信号
);

// 定义预设频率对应的分频系数
// 假设系统时钟为50MHz，计算方法: 分频系数 = 系统时钟频率 / (目标频率 * 2)
reg [15:0] SIG_MAX;

// 根据freq_sel选择分频系数
always @(*) begin
    case(freq_sel)
        3'd0: SIG_MAX = 16'd50000;  // 500Hz (50MHz / (500 * 2))
        3'd1: SIG_MAX = 16'd40000;  // 625Hz (50MHz / (625 * 2))
        3'd2: SIG_MAX = 16'd25000;  // 1KHz  (50MHz / (1000 * 2))
        3'd3: SIG_MAX = 16'd20000;  // 1.25KHz (原始频率)
        3'd4: SIG_MAX = 16'd12500;  // 2KHz
        3'd5: SIG_MAX = 16'd10000;  // 2.5KHz
        3'd6: SIG_MAX = 16'd6250;   // 4KHz
        3'd7: SIG_MAX = custom_div; // 自定义频率
        default: SIG_MAX = 16'd40000; // 默认1.25KHz
    endcase
end

// 计数器
reg [15:0] count;

// 计数器控制逻辑
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count <= 16'd0;
    else if(!en)
        count <= 16'd0;  // 禁用时重置计数器
    else begin
        if (count >= SIG_MAX - 1)
            count <= 16'd0;
        else
            count <= count + 16'd1;
    end
end

// 输出控制，保持50%占空比
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        buz <= 1'b0;
    else if(!en)
        buz <= 1'b0;  // 禁用时输出低电平
    else begin
        // 50% 占空比
        if (count < (SIG_MAX >> 1))
            buz <= 1'b1;
        else
            buz <= 1'b0;
    end
end

endmodule