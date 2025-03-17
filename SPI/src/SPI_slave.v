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

localparam              IDLE            = 0,//空闲状态
                        START           = 1,
                        TRANS           = 2,
                        WAIT            = 3,
                        OVER            = 4;
//reg define
reg [`DATA_WIDTH-1:0]   MOSI_shift;//
reg [`DATA_WIDTH-1:0]   MISO_shift;
reg [`STATE_WIDTH-1:0]  state,next_state;
reg                     DCLK_reg;//时钟信号寄存器
wire                    DCLK_edge_up;//时钟边沿检测，上升沿
wire                    DCLK_edge_down;//时钟边沿检测，下降沿
reg [`DATA_ADDR-1:0]    data_cnt;//数据计数器
wire[1:0]               CPHA_CPOL;//时钟相位和极性
//
assign MISO = MISO_shift[`DATA_WIDTH-1];//输出数据
assign CPHA_CPOL = {CPHA,CPOL};//时钟相位和极性
//时钟检测
assign DCLK_edge_up = ~DCLK_reg & DCLK;//上升沿检测
assign DCLK_edge_down = DCLK_reg & ~DCLK;//下降沿检测
//状态变化
wire IDLE_START = (state == IDLE) && (nCS == 0);//
wire START_TRANS = (state == START) && ((^CPHA_CPOL)?DCLK_edge_down:DCLK_edge_up);//高电平有效则检测上升沿，低电平有效则检测下降沿
wire TRANS_WAIT = (state == TRANS) && (data_cnt == `DATA_WIDTH - 1);//数据计数器
wire WAIT_OVER = (state == WAIT) && ((!(^CPHA_CPOL) && DCLK_edge_up) || ((^CPHA_CPOL) && DCLK_edge_down));

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        DCLK_reg <= CPOL;
    end else begin
        DCLK_reg <= DCLK;
    end
end

//状态机
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end
//状态机
always @(*) begin
    case (state)
        IDLE: begin
            if (IDLE_START) begin
                next_state = START;
            end else if (nCS)begin
                next_state = IDLE;
            end else begin
                next_state = IDLE;
            end
        end
        START:begin
            if (START_TRANS)begin
                next_state = TRANS;
            end else if (nCS)begin
                next_state = IDLE;
            end else begin
                next_state = START;
            end
        end
        TRANS:begin
            if (TRANS_WAIT)begin
                next_state = WAIT;
            end else if (nCS)begin
                next_state = IDLE;
            end else begin
                next_state = TRANS;
            end
        end
        WAIT:begin
            if (WAIT_OVER)begin
                next_state = OVER;
            end else if (nCS)begin
                next_state = IDLE;
            end else begin
                next_state = WAIT;
            end
        end
        OVER:begin
            next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase
end

always @(posedge  clk or negedge rst_n) begin
    if (!rst_n) begin
        data_cnt <= 3'd0;
    end else if (state == WAIT)begin
        data_cnt <= data_cnt;
    end else if(state == TRANS || state == START) begin 
        if (!(^CPHA_CPOL) && DCLK_edge_up) begin
            data_cnt <= data_cnt + 1;
        end else if ((^CPHA_CPOL) && DCLK_edge_down) begin
            data_cnt <= data_cnt + 1;
        end else begin
            data_cnt <= data_cnt;
        end
    end else begin
        data_cnt <= 3'd0;
    end
end

//发送数据
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin 
		MISO_shift <= {`DATA_WIDTH{1'b0}};
    end else if (state == IDLE && data_in_vld)begin
       MISO_shift <= data_in;
    end else if ((state == TRANS) || (state ==  WAIT))begin
        if (!(^CPHA_CPOL) && DCLK_edge_down)begin
            MISO_shift <= {MISO_shift[`DATA_WIDTH-2:0],MISO_shift[`DATA_WIDTH-1]};
        end else if ((^CPHA_CPOL) && DCLK_edge_up)begin
            MISO_shift <= {MISO_shift[`DATA_WIDTH-2:0],MISO_shift[`DATA_WIDTH-1]};
        end else begin
            MISO_shift <= MISO_shift;
        end
    end
end

//接收数据
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)begin
        MOSI_shift <= {`DATA_WIDTH{1'b0}};
    end else if ((state == TRANS) || (state ==  WAIT) || (state == START))begin
        if (!(^CPHA_CPOL) && DCLK_edge_up)begin
            MOSI_shift <= {MOSI_shift[`DATA_WIDTH-2:0],MOSI};
        end else if ((^CPHA_CPOL) && DCLK_edge_down)begin
            MOSI_shift <= {MOSI_shift[`DATA_WIDTH-2:0],MOSI};
        end else begin
            MOSI_shift <= MOSI_shift;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)begin
        data_out <= {`DATA_WIDTH{1'b0}};
        data_out_vld <= 1'b0;
    end else if (state == OVER)begin
        data_out <= MOSI_shift;
        data_out_vld <= 1'b1;
    end else begin
        data_out <= data_out;
        data_out_vld <= 1'b0;
    end
end

endmodule
