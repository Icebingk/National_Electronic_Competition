/*==============================================
* Function Name  : key_edge.v
* Description    : 摁键边沿检测模块，具有消抖功能，输出可选的上升沿和下降沿信号。
* input port     : clk(系统时钟),key_in(按键输入信号)
* output port    : key_edge_pos(上升沿信号), key_edge_neg(下降沿信号)
* Author         : ADBD
//==============================================*/
module key_edge(
    input  wire       clk,           // 系统时钟
    input  wire [3:0] key_in,        // 按键输入信号
    output reg  [3:0] key_edge_pos,  // 上升沿(按键释放)
    output reg  [3:0] key_edge_neg   // 下降沿(按键摁下)
);

    // 参数定义
    parameter CNT_MAX = 20'd1_000_000;  // 消抖时间，基于系统时钟频率调整，例如：20ms @ 50MHz

    // 寄存器定义
    reg [19:0] cnt[3:0];               // 4个按键的计数器
    reg [3:0] key_reg;                 // 寄存存储按键当前状态
    reg [3:0] key_reg_prev;            // 寄存存储按键前一状态
    reg [3:0] key_flag;                // 按键稳定标志

    // 按键消抖处理
    integer i;
    always @(posedge clk) begin
        for (i = 0; i < 4; i = i + 1) begin
            // 检测到按键状态变化
            if (key_in[i] != key_reg[i]) begin
                if (cnt[i] == CNT_MAX - 1) begin
                    key_reg[i] <= key_in[i];  // 更新按键状态
                    cnt[i] <= 0;
                    key_flag[i] <= 1'b1;      // 设置稳定标志
                end
                else begin
                    cnt[i] <= cnt[i] + 1'b1;  // 计数器增加
                    key_flag[i] <= 1'b0;      // 清除稳定标志
                end
            end
            else begin
                cnt[i] <= 0;                  // 按键状态没变化，计数器清零
                key_flag[i] <= 1'b0;          // 清除稳定标志
            end
        end
    end

    // 边沿检测
    always @(posedge clk) begin
        key_reg_prev <= key_reg;              // 保存前一状态用于边沿检测
        
        for (i = 0; i < 4; i = i + 1) begin
            // 按键状态已稳定且有变化时生成边沿信号
            if (key_flag[i]) begin
                // 上升沿检测 (0->1，按键释放)
                key_edge_pos[i] <= ~key_reg_prev[i] & key_reg[i];
                
                // 下降沿检测 (1->0，按键按下)
                key_edge_neg[i] <= key_reg_prev[i] & ~key_reg[i];
            end
            else begin
                // 无稳定变化时，不产生边沿信号
                key_edge_pos[i] <= 1'b0;
                key_edge_neg[i] <= 1'b0;
            end
        end
    end

endmodule