module key_edge(
    input  wire       clk,           // 系统时钟
    input  wire       rst_n,         // 低电平有效复位
    input  wire [3:0] key_in,        // 按键输入信号
    output reg  [3:0] key_edge_pos,  // 上升沿(按键释放)
    output reg  [3:0] key_edge_neg   // 下降沿(按键摁下)
);

// 同步寄存器
reg [3:0] key_r1, key_r2;

// 两级同步，防止亚稳态
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key_r1 <= 4'hF;
        key_r2 <= 4'hF;
    end else begin
        key_r1 <= key_in;     // 第一级寄存
        key_r2 <= key_r1;     // 第二级寄存
    end
end

// 边沿检测 - 产生单周期脉冲
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key_edge_pos <= 4'h0;
        key_edge_neg <= 4'h0;
    end else begin
        // 上升沿：前一状态为0，当前状态为1
        key_edge_pos <= ~key_r2 & key_r1;
        
        // 下降沿：前一状态为1，当前状态为0
        key_edge_neg <= key_r2 & ~key_r1;
    end
end

endmodule