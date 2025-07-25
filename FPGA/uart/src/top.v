module top(
    input           sys_clk,        // 系统时钟
    input           rst_n,          // 系统复位
    input           rx,             // 串口接收数据
    output          tx              // 串口发送数据
);

// 参数定义
parameter CLK_FREQ = 50_000_000;    // 时钟频率 50MHz
parameter DELAY_CYCLES = CLK_FREQ;  // 发送完成后延迟1秒再次发送

// 状态机定义
localparam IDLE = 2'b00;            // 空闲状态
localparam SEND = 2'b01;            // 发送字符状态
localparam WAIT = 2'b10;            // 等待状态

// "helloworld" 字符串 (使用ASCII码)
reg [7:0] message [0:9];            // 存储 "helloworld" 的10个字符
initial begin
    message[0] = 8'h68; // "h"
    message[1] = 8'h65; // "e"
    message[2] = 8'h6C; // "l"
    message[3] = 8'h6C; // "l"
    message[4] = 8'h6F; // "o"
    message[5] = 8'h77; // "w"
    message[6] = 8'h6F; // "o"
    message[7] = 8'h72; // "r"
    message[8] = 8'h6C; // "l"
    message[9] = 8'h64; // "d"
end

// 内部寄存器
reg [1:0]  current_state;          // 当前状态
reg [1:0]  next_state;             // 下一状态
reg [3:0]  char_index;             // 当前发送字符索引
reg [31:0] delay_counter;          // 延迟计数器

// UART接口信号
reg [7:0]  tx_data;                // 发送数据
reg        tx_valid;               // 发送有效标志
wire       tx_ready;               // 发送就绪信号
wire [7:0] rx_data;                // 接收数据
wire       rx_valid;               // 接收有效标志
reg        rx_ready;               // 接收就绪信号

// 状态转换逻辑
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// 状态转换条件
always @(*) begin
    case (current_state)
        IDLE: begin
            next_state = SEND;      // 立即开始发送
        end
        
        SEND: begin
            if (char_index == 10) begin
                next_state = WAIT;  // 所有字符已发送，进入等待状态
            end else begin
                next_state = SEND;  // 继续发送
            end
        end
        
        WAIT: begin
            if (delay_counter >= DELAY_CYCLES) begin
                next_state = IDLE;  // 延迟结束，回到空闲状态准备再次发送
            end else begin
                next_state = WAIT;  // 继续等待
            end
        end
        
        default: next_state = IDLE;
    endcase
end

// 字符发送逻辑
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        char_index <= 0;
        tx_valid <= 1'b0;
        tx_data <= 8'h00;
        delay_counter <= 0;
    end else begin
        case (current_state)
            IDLE: begin
                char_index <= 0;            // 重置字符索引
                tx_valid <= 1'b0;           // 清除发送标志
                delay_counter <= 0;         // 重置延迟计数器
            end
            
            SEND: begin
                if (tx_ready && !tx_valid && (char_index < 10)) begin
                    // 准备发送下一个字符
                    tx_data <= message[char_index];  // 设置发送数据
                    tx_valid <= 1'b1;                // 设置发送有效标志
                end else if (tx_valid && tx_ready) begin
                    // 数据已被接收，准备下一个字符
                    tx_valid <= 1'b0;                // 清除发送标志
                    char_index <= char_index + 1'b1; // 更新字符索引
                end
            end
            
            WAIT: begin
                tx_valid <= 1'b0;                    // 确保发送标志清除
                delay_counter <= delay_counter + 1'b1; // 更新延迟计数器
            end
        endcase
    end
end

// 接收处理 (本例中未使用，但保留接口完整性)
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_ready <= 1'b0;
    end else begin
        rx_ready <= rx_valid;  // 简单地在数据有效时设置就绪信号
    end
end

// 实例化UART模块
uart uart_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .rx(rx),
    .tx(tx),
    .rx_data_out(rx_data),
    .rx_valid(rx_valid),
    .rx_ready(rx_ready),
    .tx_data_in(tx_data),
    .tx_valid(tx_valid),
    .tx_ready(tx_ready)
);

endmodule