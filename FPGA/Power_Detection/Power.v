module Power (
    input   wire                     sys_clk,
    input   wire                     rst_n,
    input   wire signed   [11:0]     power_in,
    input   wire                     power_in_valid,
    output  reg           [23:0]     power_out,
    output  reg                      power_out_valid
);

// 参数定义
parameter WINDOW_SIZE = 1024;  // 滑动窗口大小
// 信号定义
wire [23:0] power_square;     // 瞬时功率（信号平方）
reg  [24+$clog2(WINDOW_SIZE):0] power_sum;
reg  [23:0] shift_reg [WINDOW_SIZE-1:0]; // 移位寄存器
// 控制寄存器
reg power_in_valid_r;
reg [$clog2(WINDOW_SIZE):0] cnt;
wire clc_begin = cnt == WINDOW_SIZE; 

// 有效信号延迟
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        power_in_valid_r <= 1'b0;
    end else begin
        power_in_valid_r <= power_in_valid;
    end
end

// 移位寄存器
genvar i;
generate
    for (i = 0; i < WINDOW_SIZE; i = i + 1) begin : shift_reg_gen
        always @(posedge sys_clk or negedge rst_n) begin
            if (!rst_n) begin
                shift_reg[i] <= 24'b0;
            end else if (power_in_valid) begin
                if (i == 0) begin
                    shift_reg[i] <= power_square;
                end else begin
                    shift_reg[i] <= shift_reg[i-1];
                end
            end else begin
                shift_reg[i] <= shift_reg[i];
            end
        end
    end
endgenerate

// 累加求和
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        power_sum <= 0;
    end else if (power_in_valid)begin
        if (clc_begin)begin
            power_sum <= power_sum - shift_reg[WINDOW_SIZE-1] + power_square;
        end else begin
            power_sum <= power_sum + power_square;
        end
    end else begin
        power_sum <= power_sum; // 保持原值
    end
end

// 计数
always @(posedge sys_clk or negedge rst_n)begin
    if (!rst_n) begin
        cnt <= 0;
    end else if (clc_begin)begin
        cnt <= cnt;
    end else if (power_in_valid_r) begin
        cnt <= cnt + 1;
    end else begin
        cnt <= cnt;
    end
end

// 计算平均值
always @(posedge sys_clk or negedge rst_n)begin
    if (!rst_n) begin
        power_out <= 24'd0;
    end else if (clc_begin) begin
        power_out <= power_sum / WINDOW_SIZE;
    end else begin
        power_out <= power_out;
    end
end

// 输出有效信号控制
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        power_out_valid <= 1'b0;
    end else if (clc_begin) begin
        power_out_valid <= 1'b1;  // 窗口满时设置有效信号
    end else begin
        power_out_valid <= 1'b0;
    end
end

Multiple0 Multiple0_inst(
    .CLK(sys_clk),
    .A(power_in),
    .B(power_in),
    .P(power_square)
);

    
endmodule