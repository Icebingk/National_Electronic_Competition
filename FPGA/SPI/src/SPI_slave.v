////////////////////////////////////////////////////////////////////////////
////更新时间：      2025年3月8日
////文件说明：      SPI模块作为从机，用于与SPI从机通信，模式可选,8bit数据位
////用途：          与单片机进行通信
////补充：          模式0：CPOL=0，CPHA=0 高电平有效，时钟上升沿采样，下降沿发送
////                模式1：CPOL=0，CPHA=1 高电平有效，时钟下降沿采样，上升沿发送
////                模式2：CPOL=1，CPHA=0 低电平有效，时钟下降沿采样，上升沿发送
////                模式3：CPOL=1，CPHA=1 低电平有效，时钟上升沿采样，下降沿发送
////////////////////////////////////////////////////////////////////////////
`include "top_define.v"
module SPI_slave(
    input   wire                    clk, // 系统时钟
    input   wire                    rst_n,// 系统时钟50MHz

    input   wire [`DATA_WIDTH-1:0]  data_in,// 写数据
    input   wire                    data_in_vld,// 写数据有效
    output  reg  [`DATA_WIDTH-1:0]  data_out,// 读数据
    output  reg                     data_out_vld,// 读数据有效

    input   wire                    nCS,// 片选信号
    input   wire                    DCLK,// 时钟信号
    input   wire                    MOSI,// 主机输出从机输入
    output  wire                    MISO,// 主机输入从机输出
    input   wire                    CPOL,// 时钟极性（0：高电平有效，1：低电平有效）
    input   wire                    CPHA // 时钟相位（0：第一个边沿采样，1：第二个边沿采样）
);

// 状态定义
localparam  IDLE  = 0,
            START = 1,
            TRANS = 2,
            WAIT  = 3,
            OVER  = 4;

// 寄存器定义
reg [`DATA_WIDTH-1:0]   MOSI_shift;
reg [`DATA_WIDTH-1:0]   MISO_shift;
reg [`STATE_WIDTH-1:0]  state, next_state;
reg                     DCLK_reg, DCLK_reg2;
reg                     MOSI_reg, MOSI_reg2;
reg                     nCS_reg, nCS_reg2;
reg [`DATA_ADDR-1:0]    data_cnt;

// 线网定义
wire                    DCLK_edge_up;
wire                    DCLK_edge_down;
wire[1:0]               CPHA_CPOL;
wire                    sample_edge;
wire                    shift_edge;

// 基础信号赋值
assign MISO = MISO_shift[`DATA_WIDTH-1];
assign CPHA_CPOL = {CPHA, CPOL};

// 边沿检测
assign DCLK_edge_up = ~DCLK_reg2 & DCLK_reg;
assign DCLK_edge_down = DCLK_reg2 & ~DCLK_reg;

// 根据SPI模式确定采样和移位的边沿
assign sample_edge = (CPHA == CPOL) ? DCLK_edge_up : DCLK_edge_down;
assign shift_edge = (CPHA == CPOL) ? DCLK_edge_down : DCLK_edge_up;

// 状态转移条件
wire IDLE_START = (state == IDLE) && (nCS_reg2 == 0);
wire START_TRANS = (state == START) && sample_edge;
wire TRANS_WAIT = (state == TRANS) && (data_cnt == `DATA_WIDTH - 1);
wire WAIT_OVER = (state == WAIT) && sample_edge;

// 使用两级寄存器同步外部信号
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        DCLK_reg <= CPOL;
        DCLK_reg2 <= CPOL;
        MOSI_reg <= 1'b0;
        MOSI_reg2 <= 1'b0;
        nCS_reg <= 1'b1;
        nCS_reg2 <= 1'b1;
    end else begin
        // 双触发器同步外部信号
        DCLK_reg <= DCLK;
        DCLK_reg2 <= DCLK_reg;
        MOSI_reg <= MOSI;
        MOSI_reg2 <= MOSI_reg;
        nCS_reg <= nCS;
        nCS_reg2 <= nCS_reg;
    end
end

// 状态机更新
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// 状态机转换逻辑
always @(*) begin
    case (state)
        IDLE:   next_state = IDLE_START ? START : IDLE;
        START:  next_state = nCS_reg2 ? IDLE : (START_TRANS ? TRANS : START);
        TRANS:  next_state = nCS_reg2 ? IDLE : (TRANS_WAIT ? WAIT : TRANS);
        WAIT:   next_state = nCS_reg2 ? IDLE : (WAIT_OVER ? OVER : WAIT);
        OVER:   next_state = nCS_reg2 ? IDLE : START;// 修改输出数据处理
        default: next_state = IDLE;
    endcase
end

// 数据计数器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_cnt <= 0;
    end else if ((state == TRANS || state == START) && sample_edge) begin
        data_cnt <= data_cnt + 1;
    end else if (state == IDLE || state == OVER) begin
        data_cnt <= 0;
    end
end

// 发送数据处理
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin 
        MISO_shift <= 0;
    end else if (state == IDLE && data_in_vld) begin
        MISO_shift <= data_in;
    end else if ((state == TRANS || state == WAIT) && shift_edge) begin
        MISO_shift <= {MISO_shift[`DATA_WIDTH-2:0], MISO_shift[`DATA_WIDTH-1]};
    end
end

// 接收数据处理
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        MOSI_shift <= 0;
    end else if (state == IDLE || state == OVER) begin
        MOSI_shift <= 0;
    end else if ((state == START || state == TRANS || state == WAIT) && sample_edge) begin
        MOSI_shift <= {MOSI_shift[`DATA_WIDTH-2:0], MOSI_reg2};
    end
end

// 输出数据处理
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 0;
        data_out_vld <= 1'b0;
    end else if (state == OVER) begin
        data_out <= MOSI_shift;
        data_out_vld <= 1'b1;
    end else begin
        data_out_vld <= 1'b0;
    end
end

endmodule