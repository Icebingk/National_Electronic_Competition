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

    // input   wire [`DATA_WIDTH-1:0]  data_in,
    // input   wire                    data_in_vld,
    input   wire                     spi_data_out_ready,
    output  wire [`DATA_WIDTH-1:0]   spi_data_out,
    output  reg                      spi_data_out_vld,

    input   wire                    CPHA,
    input   wire                    CPOL,
    input   wire                    DCLK,
    input   wire                    MOSI,
    output  wire                    MISO,
    input   wire                    nCS
);
wire [(`DATA_WIDTH-1):0]    data_out;
wire                        data_out_vld;
reg                         data_out_ready;

// SPI_Slave_O FIFO缓存
wire full;
wire wr_en;

wire empty;
wire rd_en;

wire data_in_ready;

assign wr_en = data_out_vld && !full; // 写使能信号，当数据输入有效且FIFO未满时使能写入
assign rd_en = !empty && (!spi_data_out_vld || spi_data_out_ready); // 读使能信号，当FIFO不为空且输出数据无效或输出准备好时使能读取

// 输出有效控制
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
        spi_data_out_vld <= 1'b0;
    end else if (rd_en)begin
        spi_data_out_vld <= 1'b1;
    end else begin
        spi_data_out_vld <= 1'b0;
    end
end

// 写入FIFO
always@(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out_ready <= 1'b0; // 复位时数据输出无效
    end else if (wr_en) begin
        data_out_ready <= 1'b1; // 数据输出有效
    end else begin
        data_out_ready <= 1'b0; // 数据输出无效
    end
end

// 从机接收到的数据通过FIFO缓存
SPI_Slave_O SPI_Slave_O_inst(
    .clk(sys_clk),
    .rst(!rst_n),

    .full(full),
    .din(data_out),
    .wr_en(wr_en),

    .empty(empty),
    .dout(spi_data_out),
    .rd_en(rd_en)
);

SPI_slave  SPI_slave_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    
    .data_in(16'hA0A0),
    .data_in_vld(1'b1),
    .data_in_ready(data_in_ready),

    .data_out(data_out),
    .data_out_vld(data_out_vld),
    .data_out_ready(data_out_ready),

    .nCS(nCS),
    .DCLK(DCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .CPOL(CPOL),
    .CPHA(CPHA)
  );


endmodule

