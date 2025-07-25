/*==============================================
* Function Name  : SPI_control.v
* Description    : SPI控制模块，用于控制SPI_slave字符的读写
*
* input port     : sys_clk（系统时钟）, rst_n（复位信号）, 
*                  CPHA, CPOL,（采样和发送控制）
*                  DCLK（时钟信号）, MOSI（主机输出从机输入）, nCS（片选信号）
* output port    : MISO（主机输入从机输出）
* Author         : ADBD
//==============================================*/
`include "top_define.v"
module SPI_control (
    input   wire                    sys_clk,
    input   wire                    rst_n,

    // 上层接口 - 用于接收上层数据并传输到SPI主机
    input   wire [`DATA_WIDTH-1:0]  tx_data_in,       // 来自上层的数据
    input   wire                    tx_data_in_vld,   // 上层数据有效
    output  wire                    tx_data_in_ready, // 准备好接收上层数据

    // 上层接口 - 用于向上层提供从SPI主机接收的数据
    output  wire [`DATA_WIDTH-1:0]  rx_data_out,      // 提供给上层的数据
    output  reg                     rx_data_out_vld,  // 提供给上层的数据有效
    input   wire                    rx_data_out_ready,// 上层准备好接收数据

    // SPI接口
    input   wire                    CPHA,
    input   wire                    CPOL,
    input   wire                    DCLK,
    input   wire                    MOSI,
    output  wire                    MISO,
    input   wire                    nCS
);

// 内部信号定义
wire [`DATA_WIDTH-1:0] spi_tx_data;      // 从TX FIFO读出发送给SPI模块的数据
wire                   spi_tx_data_vld;   // TX FIFO数据有效
wire                   spi_tx_data_ready; // SPI模块准备好接收数据

wire [`DATA_WIDTH-1:0] spi_rx_data;      // 从SPI模块接收的数据
wire                   spi_rx_data_vld;   // SPI接收数据有效
wire                   spi_rx_data_ready; // RX FIFO准备好接收数据

wire rx_data_out_vld_w; // RX FIFO数据有效信号

always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data_out_vld <= 1'b0; // 复位时数据无效
    end else begin
        rx_data_out_vld <= rx_data_out_vld_w; // 根据RX FIFO状态更新数据有效信号
    end
end

// TX FIFO (输入缓存) - 存储要发送给SPI主机的数据
wire tx_fifo_full;
wire tx_fifo_empty;
wire tx_fifo_rd_en;

// RX FIFO (输出缓存) - 存储从SPI主机接收的数据
wire rx_fifo_full;
wire rx_fifo_empty;
wire rx_fifo_wr_en;

// TX FIFO实例 (用于发送数据)
SPI_TX_FIFO tx_fifo_inst(
    .clk(sys_clk),
    .rst(!rst_n),
    
    // 写入端口 - 连接上层接口
    .full(tx_fifo_full),
    .din(tx_data_in),
    .wr_en(tx_data_in_vld && !tx_fifo_full),
    
    // 读取端口 - 连接SPI从机
    .empty(tx_fifo_empty),
    .dout(spi_tx_data),
    .rd_en(tx_fifo_rd_en)
);

// RX FIFO实例 (用于接收数据)
SPI_RX_FIFO rx_fifo_inst(
    .clk(sys_clk),
    .rst(!rst_n),
    
    // 写入端口 - 连接SPI从机
    .full(rx_fifo_full),
    .din(spi_rx_data),
    .wr_en(rx_fifo_wr_en),
    
    // 读取端口 - 连接上层接口
    .empty(rx_fifo_empty),
    .dout(rx_data_out),
    .rd_en(rx_data_out_ready && !rx_fifo_empty)
);

// TX FIFO读取控制 - 当SPI从机准备好接收数据且FIFO非空时读取
assign tx_fifo_rd_en = spi_tx_data_ready && !tx_fifo_empty;
// TX FIFO数据有效信号
assign spi_tx_data_vld = !tx_fifo_empty;
// 上层写入就绪信号
assign tx_data_in_ready = !tx_fifo_full;

// RX FIFO写入控制 - 当SPI从机有有效数据且FIFO未满时写入
assign rx_fifo_wr_en = spi_rx_data_vld && !rx_fifo_full;
// RX FIFO数据有效信号
assign rx_data_out_vld_w = !rx_fifo_empty;
// SPI从机接收就绪信号
assign spi_rx_data_ready = !rx_fifo_full;

// SPI从机实例
SPI_slave SPI_slave_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    
    // 发送数据接口
    .data_in(spi_tx_data),
    .data_in_vld(spi_tx_data_vld),
    .data_in_ready(spi_tx_data_ready),

    // 接收数据接口
    .data_out(spi_rx_data),
    .data_out_vld(spi_rx_data_vld),
    .data_out_ready(spi_rx_data_ready),

    // SPI接口
    .nCS(nCS),
    .DCLK(DCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .CPOL(CPOL),
    .CPHA(CPHA)
);

endmodule