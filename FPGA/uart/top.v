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
assign mode = 3'b011;  // 设置模式为011

// 定义内部信号
wire [7:0] rx_data_out;
wire rx_valid;
wire rx_ready;

// SPI接口信号(16位)
wire [15:0] spi_data_out;
wire spi_data_out_vld;
reg spi_data_out_ready;

// UART发送接口信号(8位)
reg [7:0] tx_data_in;
reg tx_valid;
wire tx_ready;

// 16位到8位转换状态机定义
localparam IDLE = 3'b000;
localparam SEND_HIGH = 3'b001;
localparam WAIT_HIGH = 3'b010;
localparam SEND_LOW = 3'b011;
localparam WAIT_LOW = 3'b100;

reg [2:0] state;
reg [15:0] spi_data_buffer; // 缓存SPI数据

// 状态机实现 - 16位转8位并发送
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        tx_valid <= 1'b0;
        tx_data_in <= 8'h00;
        spi_data_out_ready <= 1'b1; // 初始时准备好接收SPI数据
        spi_data_buffer <= 16'h0000;
    end else begin
        case (state)
            IDLE: begin
                // 收到SPI数据，准备发送
                if (spi_data_out_vld && spi_data_out_ready) begin
                    spi_data_buffer <= spi_data_out; // 缓存SPI数据
                    spi_data_out_ready <= 1'b0; // 不再接收新数据
                    state <= SEND_HIGH;
                end else begin
                    tx_valid <= 1'b0;
                    spi_data_out_ready <= 1'b1; // 准备接收SPI数据
                end
            end
            
            SEND_HIGH: begin
                // 发送高8位
                if (tx_ready) begin
                    tx_data_in <= spi_data_buffer[15:8]; // 发送高8位
                    tx_valid <= 1'b1;
                    state <= WAIT_HIGH;
                end
            end
            
            WAIT_HIGH: begin
                // 等待高8位发送完成
                if (tx_valid) begin
                    tx_valid <= 1'b0; // 清除发送请求
                end else if (tx_ready && !tx_valid) begin
                    state <= SEND_LOW; // 高8位发送完成，准备发送低8位
                end
            end
            
            SEND_LOW: begin
                // 发送低8位
                if (tx_ready) begin
                    tx_data_in <= spi_data_buffer[7:0]; // 发送低8位
                    tx_valid <= 1'b1;
                    state <= WAIT_LOW;
                end
            end
            
            WAIT_LOW: begin
                // 等待低8位发送完成
                if (tx_valid) begin
                    tx_valid <= 1'b0; // 清除发送请求
                end else if (tx_ready && !tx_valid) begin
                    state <= IDLE; // 所有数据发送完成，回到空闲状态
                end
            end
        endcase
    end
end

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

SPI_control SPI_control_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),

    .spi_data_out_ready(spi_data_out_ready),  // 使用标准握手信号
    .spi_data_out(spi_data_out),
    .spi_data_out_vld(spi_data_out_vld),

    .CPHA(CPHA),
    .CPOL(CPOL),
    .DCLK(DCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .nCS(nCS)
);

endmodule