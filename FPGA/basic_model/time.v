module timer (
    input  wire         clk,         // 系统时钟
    input  wire         rst_n,       // 低电平复位
    input  wire         enable,      // 定时器使能
    input  wire [31:0]  interval,    // 定时间隔值 (时钟周期数)
    output reg          timer_pulse, // 定时脉冲输出
    output reg          timer_out,   // 分频后的时钟输出
    output reg  [3:0]   n_num        //剩余时间 
);

localparam FRE = 50_000_000;
    // 定时计数器
    reg [31:0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            n_num <= interval / FRE; 
        end else begin
            n_num <= interval / FRE - counter / FRE;
        end
    end

    // 定时器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位状态
            counter <= 32'd0;
            timer_pulse <= 1'b0;
        end else if (!enable) begin
            // 定时器启用
            if (counter >= interval - 1) begin
                // 达到定时间隔
                timer_out <= ~timer_out;  // 翻转输出，产生分频时钟
                counter <= 32'd0;           // 重置计数器
                timer_pulse <= 1'b1;        // 产生脉冲
            end else begin
                // 继续计数
                counter <= counter + 1'b1;
                timer_pulse <= 1'b0;
            end
        end else begin
            // 定时器禁用
            counter <= 32'd0;
            timer_pulse <= 1'b0;
        end
    end

endmodule