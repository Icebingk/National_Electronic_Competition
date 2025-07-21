/*==============================================
* Function Name  : reset_n.v
* Description    : 复位信号生成模块,异步置零，
*                  同步复位，置零保持10个周期  
* input port     : sys_clk（系统时钟），rst_in_n（外部复位信号，低电平有效）
* output port    : rst_out_n（输出复位信号，低电平有效）
* Author         : ADBD
//==============================================*/
module reset_n(
    input  wire sys_clk,       // 系统时钟
    input  wire rst_in_n,  // 外部复位信号，低电平有效
    output reg  rst_out_n  // 输出复位信号，低电平有效
);

    // 定义参数和内部变量
    parameter RST_CYCLES = 10;  // 复位保持的时钟周期数
    reg [3:0] counter;          // 计数器，4位可以计到15，足够计10个周期
    reg rst_sync1_n;            // 第一级同步寄存器
    reg rst_sync2_n;            // 第二级同步寄存器
    reg rst_trigger;            // 复位触发标志

    // 两级同步器，用于同步复位释放
    always @(posedge sys_clk or negedge rst_in_n) begin
        if (!rst_in_n) begin
            // 异步复位
            rst_sync1_n <= 1'b0;
            rst_sync2_n <= 1'b0;
        end else begin
            // 同步释放
            rst_sync1_n <= 1'b1;
            rst_sync2_n <= rst_sync1_n;
        end
    end

    // 复位计数和控制逻辑
    always @(posedge sys_clk or negedge rst_in_n) begin
        if (!rst_in_n) begin
            // 异步复位，立即复位
            counter <= 4'd0;
            rst_out_n <= 1'b0;
            rst_trigger <= 1'b1;
        end else begin
            if (!rst_sync2_n) begin
                // 同步复位状态，保持复位状态
                counter <= 4'd0;
                rst_out_n <= 1'b0;
                rst_trigger <= 1'b1;
            end else if (rst_trigger) begin
                // 复位释放后开始计数
                if (counter < RST_CYCLES - 1) begin
                    counter <= counter + 1'b1;
                    rst_out_n <= 1'b0;
                end else begin
                    // 计数完成，释放复位
                    counter <= 4'd0;
                    rst_out_n <= 1'b1;
                    rst_trigger <= 1'b0;
                end
            end else begin
                // 稳定状态
                counter <= 4'd0;
                rst_out_n <= 1'b1;
                rst_trigger <= 1'b0;
            end
        end
    end

endmodule