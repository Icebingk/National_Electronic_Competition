module uart(
    input           sys_clk,            // 系统时钟
    input           rst_n,            // 系统复位
    
    // UART物理接口
    input           rx,             // 串口接收数据
    output          tx,             // 串口发送数据
    
    // 外部接收数据接口(UART->外部模块)
    output [7:0]    rx_data_out,    // 接收到的数据
    output          rx_valid,       // 接收数据有效标志
    input           rx_ready,       // 外部模块读取就绪信号
    
    // 外部发送数据接口(外部模块->UART)
    input  [7:0]    tx_data_in,     // 要发送的数据
    input           tx_valid,       // 外部发送数据有效标志
    output          tx_ready        // UART发送就绪标志
);

// 系统参数
parameter CLK_FREQ = 50_000_000;    // 时钟频率 50MHz
parameter RX_BUFFER_SIZE = 64;      // 接收缓冲区大小
parameter TX_BUFFER_SIZE = 64;      // 发送缓冲区大小

// 状态机定义
localparam IDLE      = 2'b01;       // 空闲状态
localparam SEND_DATA = 2'b10;       // 发送数据状态

//-------- 接收缓冲区 --------
reg [7:0]  rx_buffer[0:RX_BUFFER_SIZE-1];  // 接收数据缓冲区
reg [5:0]  rx_wr_ptr;               // 接收缓冲区写指针
reg [5:0]  rx_rd_ptr;               // 接收缓冲区读指针

//-------- 发送缓冲区 --------
reg [7:0]  tx_buffer[0:TX_BUFFER_SIZE-1];  // 发送数据缓冲区
reg [5:0]  tx_wr_ptr;               // 发送缓冲区写指针
reg [5:0]  tx_rd_ptr;               // 发送缓冲区读指针

//-------- UART控制寄存器 --------
reg [1:0]  current_state;           // 当前状态
reg [1:0]  next_state;              // 下一状态
reg [7:0]  uart_tx_data;            // UART发送数据
reg        uart_tx_valid;           // UART发送有效标志

//-------- 内部连线 --------
wire [7:0] uart_rx_data;            // UART接收的数据
wire       uart_rx_valid;           // UART接收数据有效
wire       uart_tx_ready;           // UART发送器就绪

//-------- 缓冲区状态 --------
wire rx_buffer_empty = (rx_wr_ptr == rx_rd_ptr);
wire rx_buffer_full  = ((rx_wr_ptr + 1'b1) == rx_rd_ptr) || 
                      ((rx_wr_ptr == RX_BUFFER_SIZE-1) && (rx_rd_ptr == 0));

wire tx_buffer_empty = (tx_wr_ptr == tx_rd_ptr);
wire tx_buffer_full  = ((tx_wr_ptr + 1'b1) == tx_rd_ptr) || 
                      ((tx_wr_ptr == TX_BUFFER_SIZE-1) && (tx_rd_ptr == 0));

//-------- 外部接口信号 --------
assign rx_data_out = rx_buffer[rx_rd_ptr];
assign rx_valid = !rx_buffer_empty;
assign tx_ready = !tx_buffer_full;

//======== 接收数据处理 ========
// 接收缓冲区写入控制
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_wr_ptr <= 6'd0;
    end else begin
        // 从UART接收模块获取数据
        if (uart_rx_valid && !rx_buffer_full) begin
            rx_buffer[rx_wr_ptr] <= uart_rx_data;
            rx_wr_ptr <= (rx_wr_ptr == RX_BUFFER_SIZE-1) ? 6'd0 : (rx_wr_ptr + 1'b1);
        end
    end
end

// 接收缓冲区读取控制
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_rd_ptr <= 6'd0;
    end else begin
        // 外部模块读取数据
        if (rx_ready && rx_valid) begin
            rx_rd_ptr <= (rx_rd_ptr == RX_BUFFER_SIZE-1) ? 6'd0 : (rx_rd_ptr + 1'b1);
        end
    end
end

//======== 发送数据处理 ========
// 发送缓冲区写入控制
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_wr_ptr <= 6'd0;
    end else begin
        // 外部模块写入发送数据
        if (tx_valid && tx_ready) begin
            tx_buffer[tx_wr_ptr] <= tx_data_in;
            tx_wr_ptr <= (tx_wr_ptr == TX_BUFFER_SIZE-1) ? 6'd0 : (tx_wr_ptr + 1'b1);
        end
    end
end

// 发送缓冲区读取控制
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_rd_ptr <= 6'd0;
    end else begin
        // UART发送模块读取数据
        if (current_state == SEND_DATA && uart_tx_ready && uart_tx_valid) begin
            tx_rd_ptr <= (tx_rd_ptr == TX_BUFFER_SIZE-1) ? 6'd0 : (tx_rd_ptr + 1'b1);
        end
    end
end

//======== 状态机控制 ========
// 状态转换
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// 状态转换逻辑
always @(*) begin
    case (current_state)
        IDLE: begin
            if (!tx_buffer_empty) begin
                next_state = SEND_DATA;  // 有数据待发送
            end else begin
                next_state = IDLE;
            end
        end
        
        SEND_DATA: begin
            if (tx_buffer_empty && uart_tx_ready && !uart_tx_valid) begin
                next_state = IDLE;  // 发送完成返回空闲
            end else begin
                next_state = SEND_DATA;
            end
        end
        
        default: next_state = IDLE;
    endcase
end

// UART发送控制
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        uart_tx_data <= 8'h00;
        uart_tx_valid <= 1'b0;
    end else begin
        case (current_state)
            IDLE: begin
                uart_tx_valid <= 1'b0;
            end
            
            SEND_DATA: begin
                if (uart_tx_ready && !uart_tx_valid && !tx_buffer_empty) begin
                    // 从发送缓冲区读取数据发送
                    uart_tx_data <= tx_buffer[tx_rd_ptr];
                    uart_tx_valid <= 1'b1;
                end else if (uart_tx_valid) begin
                    // 数据已被接收，清除有效标志
                    uart_tx_valid <= 1'b0;
                end
            end
            
            default: begin
                uart_tx_valid <= 1'b0;
            end
        endcase
    end
end

//======== UART核心模块 ========
// 实例化UART接收模块
uart_rx #(
    .MAX_BPS(115200),
    .CLOCK(CLK_FREQ),
    .CHECK_BIT("None")
) rx_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .rx(rx),
    .rx_data_vld(uart_rx_valid),
    .rx_data(uart_rx_data)
);

// 实例化UART发送模块
uart_tx #(
    .MAX_BPS(115200),
    .CLOCK(CLK_FREQ),
    .CHECK_BIT("None")
) tx_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .tx_data(uart_tx_data),
    .tx_data_vld(uart_tx_valid),
    .ready(uart_tx_ready),
    .tx(tx)
);

endmodule