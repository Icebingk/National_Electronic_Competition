module top(
  input wire sys_clk,
  input wire rst_n,

  input wire rx,
  output wire tx,

  input wire CPHA,
  input wire CPOL,
  input wire DCLK,
  input wire MOSI,
  output wire MISO,
  input wire nCS
);

// 添加内部信号声明
wire [7:0] rx_data_out;
wire rx_valid;
wire rx_ready = 0;
wire [15:0] spi_data_out;  // 16位SPI数据
wire spi_data_out_vld;
wire tx_ready;

// 数据分割和发送控制信号
reg [15:0] spi_data_reg;
reg [7:0] tx_data_in;
reg tx_valid;
reg send_state;  // 0: 发送低8位, 1: 发送高8位
reg spi_data_received;

// SPI数据分割和UART发送控制逻辑
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_data_reg <= 16'b0;
        tx_data_in <= 8'b0;
        tx_valid <= 1'b0;
        send_state <= 1'b0;
        spi_data_received <= 1'b0;
    end else begin
        // 当SPI数据有效时，保存数据并开始发送流程
        if (spi_data_out_vld && !spi_data_received) begin
            spi_data_reg <= spi_data_out;
            spi_data_received <= 1'b1;
            send_state <= 1'b0;  // 从低8位开始发送
            tx_data_in <= spi_data_out[7:0];  // 先发送低8位
            tx_valid <= 1'b1;
        end
        // 当UART准备好接收且当前数据被接受时
        else if (tx_ready && tx_valid && spi_data_received) begin
            if (send_state == 1'b0) begin
                // 已发送低8位，准备发送高8位
                send_state <= 1'b1;
                tx_data_in <= spi_data_reg[15:8];  // 发送高8位
                tx_valid <= 1'b1;
            end else begin
                // 已发送高8位，完成一次16位数据传输
                tx_valid <= 1'b0;
                spi_data_received <= 1'b0;
                send_state <= 1'b0;
            end
        end
        // 如果没有新的SPI数据且不在发送过程中，保持tx_valid为0
        else if (!spi_data_received) begin
            tx_valid <= 1'b0;
        end
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

    .spi_data_out_ready(!spi_data_out_vld),  // 始终准备接收SPI数据
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