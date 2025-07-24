module top (
    input        sys_clk,    // 系统时钟
    input        rst_n,      // 系统复位，低电平有效
    input        rx,         // UART接收
    output       tx          // UART发送
);

// 参数定义
parameter CLK_FREQ = 50_000_000;           // 系统时钟频率
parameter DELAY_MS = 1000;                 // 发送间隔(毫秒)
parameter DELAY_CYCLES = CLK_FREQ/1000*DELAY_MS; // 延时周期数

// HelloWorld字符串定义
localparam MSG_LEN = 10;
reg [7:0] hello_msg [0:MSG_LEN-1];
initial begin
    hello_msg[0] = "H";  // 0x48
    hello_msg[1] = "e";  // 0x65
    hello_msg[2] = "l";  // 0x6C
    hello_msg[3] = "l";  // 0x6C
    hello_msg[4] = "o";  // 0x6F
    hello_msg[5] = "W";  // 0x57
    hello_msg[6] = "o";  // 0x6F
    hello_msg[7] = "r";  // 0x72
    hello_msg[8] = "l";  // 0x6C
    hello_msg[9] = "d";  // 0x64
end

// 状态机定义
localparam IDLE       = 3'b001;
localparam SEND_CHAR  = 3'b010;
localparam DELAY      = 3'b100;

// 寄存器定义
reg [2:0]  current_state;
reg [2:0]  next_state;
reg [31:0] delay_cnt;
reg [3:0]  char_index;
reg [7:0]  tx_data;
reg        tx_valid;
wire       tx_ready;
wire [7:0] rx_data;
wire       rx_valid;
reg        rx_ready;

// UART模块实例化
uart uart_inst (
    .sys_clk    (sys_clk),
    .rst_n      (rst_n),
    .rx         (rx),
    .tx         (tx),
    .rx_data_out(rx_data),
    .rx_valid   (rx_valid),
    .rx_ready   (rx_ready),
    .tx_data_in (tx_data),
    .tx_valid   (tx_valid),
    .tx_ready   (tx_ready)
);

// 状态机转换
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// 状态机逻辑
always @(*) begin
    case (current_state)
        IDLE: begin
            next_state = SEND_CHAR;
        end
        
        SEND_CHAR: begin
            if (tx_ready && tx_valid) begin
                if (char_index == MSG_LEN - 1) 
                    next_state = DELAY;
                else
                    next_state = SEND_CHAR;
            end else begin
                next_state = SEND_CHAR;
            end
        end
        
        DELAY: begin
            if (delay_cnt >= DELAY_CYCLES - 1)
                next_state = IDLE;
            else
                next_state = DELAY;
        end
        
        default: next_state = IDLE;
    endcase
end

// 字符索引控制
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        char_index <= 4'd0;
    end else if (current_state == IDLE) begin
        char_index <= 4'd0;
    end else if (current_state == SEND_CHAR && tx_ready && tx_valid) begin
        if (char_index == MSG_LEN - 1)
            char_index <= 4'd0;
        else
            char_index <= char_index + 1'b1;
    end
end

// 延时计数器
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        delay_cnt <= 32'd0;
    end else if (current_state == DELAY) begin
        if (delay_cnt >= DELAY_CYCLES - 1)
            delay_cnt <= 32'd0;
        else
            delay_cnt <= delay_cnt + 1'b1;
    end else begin
        delay_cnt <= 32'd0;
    end
end

// TX数据控制
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_data <= 8'd0;
        tx_valid <= 1'b0;
    end else begin
        case (current_state)
            IDLE: begin
                tx_valid <= 1'b0;
            end
            
            SEND_CHAR: begin
                if (tx_ready && !tx_valid) begin
                    tx_data <= hello_msg[char_index];
                    tx_valid <= 1'b1;
                end else if (tx_ready && tx_valid) begin
                    tx_valid <= 1'b0;
                end
            end
            
            default: begin
                tx_valid <= 1'b0;
            end
        endcase
    end
end

// 接收数据控制（本例中未使用接收功能，但保持接口完整）
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_ready <= 1'b1;
    end else begin
        rx_ready <= 1'b1;  // 始终准备接收数据
    end
end

endmodule