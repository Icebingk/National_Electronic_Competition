////////////////////////////////////////////////////////////////////////////
////更新时间：      2025年2月17日
////文件说明：      SPI模块作为主机，用于与SPI从机通信，模式可选，双工模式,数据位宽可改
////用途：          与单片机进行通信
////补充：          模式0：CPOL=0，CPHA=0 时钟上升沿采样，下降沿发送
////                模式1：CPOL=0，CPHA=1 时钟下降沿采样，上升沿发送
////                模式2：CPOL=1，CPHA=0 时钟下降沿采样，上升沿发送
////                模式3：CPOL=1，CPHA=1 时钟上升沿采样，下降沿发送
////////////////////////////////////////////////////////////////////////////
`include "top_define.v"
module spi_master(
	input  	wire                   			clk		,//系统时钟	
	input  	wire                   			rst_n	,//系统复位信号
	input  	wire                   			nCS_ctrl,//片选控制信号
	input	wire	[`SPI_CLK_DIV-1:0]		clk_div	,//spi时钟分频
	input  	wire                   			wr_req	,//写请求
	output 	wire                   			wr_ack	,//写应答
	input	wire	[`DATA_WIDTH-1:0]		data_in	,//写数据
	output	wire	[`DATA_WIDTH-1:0]       data_out,//读数据
	
	output 	wire                   			nCS		,//片选信号
	output 	wire                   			DCLK	,//时钟信号
	output 	wire                   			MOSI	,//主机输出从机输入
	input  	wire                   			MISO	,//主机输入从机输出
	input  	wire                   			CPOL	,//时钟极性（0：高电平有效，1：低电平有效）
	input  	wire                   			CPHA	 //时钟相位（0：第一个边沿采样，1：第二个边沿采样）
);

//Reg define
reg                     DCLK_reg	;			//时钟信号寄存器
reg	[`DATA_WIDTH-1:0] 	MOSI_shift	;			//主机输出从机输入数据寄存器
reg	[`DATA_WIDTH-1:0] 	MISO_shift	;			//主机输入从机输出数据寄存器
reg	[`STATE_WIDTH-1:0]	state		;			//状态寄存器
reg	[`STATE_WIDTH-1:0]	next_state	;			//下一个状态寄存器
reg [`SPI_CLK_DIV-1:0]	clk_cnt		;			//时钟计数器
reg	[`SPI_CLK_EDGE-1:0] clk_edge_cnt;			//时钟边沿计数器

localparam				IDLE            = 0,	//空闲状态
						DCLK_IDLE       = 1,	//时钟空闲状态
						DCLK_EDGE       = 2,	//时钟边沿状态
						ACK             = 3,	//应答状态
						LAST_HALF_CYCLE = 4,	//最后半周期状态 
						ACK_WAIT        = 5;	//等待应答状态

assign MOSI = MOSI_shift[`DATA_WIDTH-1];		//主机输出从机输入	
assign data_out = MISO_shift	;				//主机输入从机输出
assign nCS = nCS_ctrl			;				//片选信号	
assign DCLK = DCLK_reg			;				//时钟信号连线			
assign wr_ack = (state == ACK)	;				//应答

//
always@(posedge clk or negedge rst_n)	begin
	if(!rst_n)
		state <= IDLE;
	else
		state <= next_state;
end

always@(*)	begin
	case(state)
		IDLE:
			if(wr_req == 'b1)//写请求
				next_state <= DCLK_IDLE;
			else
				next_state <= IDLE;
		DCLK_IDLE:
			if(clk_cnt == clk_div)//时钟分频，度过空闲状态，此时spi时钟还是和IDLE相同的空闲状态
				next_state <= DCLK_EDGE;
			else
				next_state <= DCLK_IDLE;
		DCLK_EDGE: 
			if(clk_edge_cnt == 5'd15)//传输数据状态，计数时钟边沿
				next_state <= LAST_HALF_CYCLE;
			else
				next_state <= DCLK_IDLE;	
		LAST_HALF_CYCLE:
			if(clk_cnt == clk_div)//时钟分频，时钟有效时，时钟边沿计数
				next_state <= ACK;
			else
				next_state <= LAST_HALF_CYCLE; 	
		ACK:
			next_state <= ACK_WAIT;//应答状态
		ACK_WAIT:
			next_state <= IDLE;//应答等待状态
		default:
			next_state <= IDLE;
	endcase
end

//
always@(posedge clk or negedge rst_n)	begin
	if(!rst_n)
		DCLK_reg <= 'b0;
	else if(state == IDLE)//空闲状态时钟保持空闲状态CPOL
		DCLK_reg <= CPOL;
	else if(state == DCLK_EDGE)//传输数据状态时钟翻转
		DCLK_reg <= ~DCLK_reg;			
end

//
always@(posedge clk or negedge rst_n)	begin
	if(!rst_n)
		clk_cnt <= {`SPI_CLK_DIV{1'b0}};
	else if(state == DCLK_IDLE || state == LAST_HALF_CYCLE)//时钟分频在最前和最后后半周期
		clk_cnt <= clk_cnt + 'd1;
	else
		clk_cnt <= {`SPI_CLK_DIV{1'b0}};
end

//
always@(posedge clk or negedge rst_n)	begin
	if(!rst_n)
		clk_edge_cnt <= {`SPI_CLK_EDGE{1'b0}};
	else if(state == DCLK_EDGE)//时钟边沿计数
		clk_edge_cnt <= clk_edge_cnt + 'd1;
	else if(state == IDLE)
		clk_edge_cnt <= {`SPI_CLK_EDGE{1'b0}};
end

//
always@(posedge clk or negedge rst_n)	begin
	if(!rst_n)
		MOSI_shift <= {`DATA_WIDTH{1'b0}};
	else if(state == IDLE && wr_req)
		MOSI_shift <= data_in;			
	else if(state == DCLK_EDGE)			
		if(CPHA == 1'b0 && clk_edge_cnt[0] == 'b1)	//下降沿变化
			MOSI_shift <= {MOSI_shift[`DATA_WIDTH-2:0],MOSI_shift[`DATA_WIDTH-1]};	
		else if(CPHA == 1'b1 && (clk_edge_cnt != {`SPI_CLK_EDGE{1'b0}} && clk_edge_cnt[0] == 'b0))//上升沿变化
			MOSI_shift <= {MOSI_shift[`DATA_WIDTH-2:0],MOSI_shift[`DATA_WIDTH-1]};
end

//
always@(posedge clk or negedge rst_n)	begin
	if(!rst_n)
		MISO_shift <= {`DATA_WIDTH{1'b0}};
	else if(state == IDLE && wr_req)
		MISO_shift <= {`DATA_WIDTH{1'b0}};
	else if(state == DCLK_EDGE)
		if(CPHA == 'b0 && clk_edge_cnt[0] == 'b0)//上升沿采样
			MISO_shift <= {MISO_shift[`DATA_WIDTH-2:0],MISO};
		else if(CPHA == 'b1 && (clk_edge_cnt[0] == 'b1))//下降沿变化
			MISO_shift <= {MISO_shift[`DATA_WIDTH-2:0],MISO};
end

endmodule 
