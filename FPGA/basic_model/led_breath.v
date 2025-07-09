/*==============================================
* Function Name  : led_breath.v
* Description    : 这个模块实现了LED灯的呼吸效果。在每个周期内，LED灯的亮度会逐渐增加到最大值，然后再逐渐减小到最小值。
*                  8个灯的亮度是相同的。
*                  该模块使用了三个计数器：us计数器、ms计数器和1s计数器。us计数器用于生成1us的时钟信号，ms计数器用于生成1ms的时钟信号，
*                  1s计数器用于生成1s的时钟信号。利用ms计数器和1s计数器的比较来实现PWM调制，从而控制LED的亮度变化。
*                  呼吸周期约为2秒，分为渐亮1秒和渐暗1秒两个阶段。
*                  在渐亮阶段，随着时间推移，LED的亮灯时间逐渐增加；在渐暗阶段，LED的亮灯时间逐渐减少。
* input port     : clk(系统时钟), rst(全局复位信号)
* output port    : led(LED输出信号，控制8个LED，低电平点亮)
* Author         : ADBD
//==============================================*/


module led_breath(
    input   wire                clk,        // 系统时钟，频率为50MHz
    input   wire                rst,        // 全局复位信号，高电平有效
    output  reg     [7:0]       led         // LED输出信号，控制8个LED，低电平点亮
);

// 定义计数器参数
parameter   COUNTER_US = 6'd49;             // 1微秒计数值 (50MHz时钟，计数50-1=49)
parameter   COUNTER_MS = 10'd999;           // 1毫秒计数值 (1000微秒-1=999)
parameter   COUNTER_1S = 10'd999;           // 1秒计数值 (1000毫秒-1=999)

// 计数器寄存器
reg [5:0]   count_us;                       // 微秒计数器，计数范围0-49
reg [9:0]   count_ms;                       // 毫秒计数器，计数范围0-999
reg [9:0]   count_1s;                       // 秒计数器，计数范围0-999
reg         cnt_1s_en;                      // 控制信号，用于切换明暗阶段


// 微秒计数器 - 基于50MHz时钟，每50个时钟周期产生1微秒
always@(posedge clk or posedge rst)
    if(rst)
        count_us <= 6'b0;                   // 复位时清零
    else if(count_us == COUNTER_US)
        count_us <= 6'b0;                   // 计数到最大值后归零
    else
        count_us <= count_us + 1;           // 正常计数递增

// 毫秒计数器 - 基于微秒计数器，每1000微秒产生1毫秒
always@(posedge clk or posedge rst)
    if(rst)
        count_ms <= 10'b0;                  // 复位时清零
    else if(count_ms == COUNTER_MS && count_us == COUNTER_US)
        count_ms <= 10'b0;                  // 计数到最大值且微秒计数器也到最大值时归零
    else if(count_us == COUNTER_US)
        count_ms <= count_ms + 1;           // 每当微秒计数满时递增

// 秒计数器 - 基于毫秒计数器，每1000毫秒产生1秒
always@(posedge clk or posedge rst)
    if(rst)
        count_1s <= 10'b0;                  // 复位时清零
    else if(count_1s == COUNTER_1S && count_ms == COUNTER_MS && count_us == COUNTER_US)
        count_1s <= 10'b0;                  // 计数到最大值且更低级计数器也到最大值时归零
    else if(count_ms == COUNTER_MS && count_us == COUNTER_US)
        count_1s <= count_1s + 1;           // 每当毫秒计数满时递增


// 亮度控制阶段切换 - 每秒切换一次(渐亮/渐暗)
always@(posedge clk or posedge rst) begin
    if(rst) begin
        cnt_1s_en <= 1'b0;                  // 复位时设为渐亮阶段
    end else if(count_1s == COUNTER_1S && count_ms == COUNTER_MS && count_us == COUNTER_US) begin
        cnt_1s_en <= ~cnt_1s_en;            // 每秒翻转一次，切换亮度变化方向
    end
end

// LED输出控制 - 通过PWM调制实现呼吸效果
always@(posedge clk or posedge rst) begin
    if(rst) begin
        led <= 8'b1111_1111;                // 复位时LED全灭
    end else if((cnt_1s_en == 1 && count_ms < count_1s) ||  (cnt_1s_en == 1'b0 && count_ms > count_1s)) begin
        led <= 8'b1111_1111;                // LED灭的条件:
                                            // 渐暗阶段(cnt_1s_en=1)时，当count_ms小于count_1s
                                            // 渐亮阶段(cnt_1s_en=0)时，当count_ms大于count_1s
    end else begin
        led <= 8'b0000_0000;                // 其他情况LED亮
    end
end

endmodule