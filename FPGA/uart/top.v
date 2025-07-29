module top(
  input wire sys_clk,
  input wire rst_n,

  input wire rx,
  output wire tx,

  output wire [2:0] mode,

  input wire CPHA,
  input wire CPOL,
  input wire DCLK,
  input wire MOSI,
  output wire MISO,
  input wire nCS
);

// 内部信号定义
wire [7:0] rx_data_out;      // UART接收数据
wire rx_valid;               // UART接收数据有效
wire rx_ready;               // UART接收就绪

wire [7:0] tx_data_in;       // UART发送数据
wire tx_valid;               // UART发送数据有效
wire tx_ready;               // UART发送就绪

wire [15:0] spi_rx_data;     // SPI接收到的16位数据
wire spi_rx_data_vld;        // SPI接收数据有效
wire spi_rx_data_ready;      // SPI接收就绪

wire [15:0] spi_tx_data;     // 发送给SPI的16位数据
wire spi_tx_data_vld;        // SPI发送数据有效
wire spi_tx_data_ready;      // SPI发送就绪

// 状态机定义
reg [1:0] state;
localparam IDLE = 2'b00;
localparam SEND_LOW = 2'b01;
localparam SEND_HIGH = 2'b10;

// 数据缓存寄存器
reg [15:0] data_buffer;

// UART实例
uart uart_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),

    .rx(rx),
    .tx(tx),

    .rx_data_out(rx_data_out),
    .rx_valid(rx_valid),
    .rx_ready(rx_ready),

    .tx_data_in(tx_data_in),
    .tx_valid(tx_valid),
    .tx_ready(tx_ready)
);

// SPI控制实例
SPI_control SPI_control_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),

    .tx_data_in(spi_tx_data),
    .tx_data_in_vld(spi_tx_data_vld),
    .tx_data_in_ready(spi_tx_data_ready),

    .rx_data_out(spi_rx_data),
    .rx_data_out_vld(spi_rx_data_vld),
    .rx_data_out_ready(spi_rx_data_ready),

    .CPHA(CPHA),
    .CPOL(CPOL),
    .DCLK(DCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .nCS(nCS)
);

// 状态机实现 - 控制16位SPI数据分两次发送给UART
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        data_buffer <= 16'h0000;
    end else begin
        case (state)
            IDLE: begin
                // 当SPI有有效数据时，缓存数据并准备发送低8位
                if (spi_rx_data_vld) begin
                    data_buffer <= spi_rx_data;
                    state <= SEND_LOW;
                end
            end
            
            SEND_LOW: begin
                // 当UART准备好发送，先发送低8位
                if (tx_ready) begin
                    state <= SEND_HIGH;
                end
            end
            
            SEND_HIGH: begin
                // 当UART准备好发送，再发送高8位
                if (tx_ready) begin
                    state <= IDLE;
                end
            end
            
            default: state <= IDLE;
        endcase
    end
end

// UART发送数据选择
assign tx_data_in = (state == SEND_LOW) ? data_buffer[7:0] : 
                    (state == SEND_HIGH) ? data_buffer[15:8] : 
                    8'h00;

// UART发送有效信号控制
assign tx_valid = (state == SEND_LOW || state == SEND_HIGH);

// SPI接收就绪信号 - 只有在空闲状态才接收新数据
assign spi_rx_data_ready = (state == IDLE);

// 处理从UART接收到的数据转发到SPI (如果需要)
assign spi_tx_data = {8'h00, rx_data_out};  // 简单示例，可根据需要修改
assign spi_tx_data_vld = rx_valid;

// 模式指示灯 (可根据需要自定义)
assign mode = 3'd3;

endmodule