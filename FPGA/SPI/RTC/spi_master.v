module spi_master(
	input  	wire                    clk		,//系统时钟	
	input  	wire                    rst		,//系统复位信号
	output 	wire                    nCS		,//片选信号
	output 	wire                    DCLK	,//时钟信号
	output 	wire                    MOSI	,//主机输出从机输入
	input  	wire                    MISO	,//主机输入从机输出
	input  	wire                    CPOL	,//时钟极性（0：高电平有效，1：低电平有效）
	input  	wire                    CPHA	,//时钟相位（0：第一个边沿采样，1：第二个边沿采样）
	input  	wire                    nCS_ctrl,//片选控制信号
	input	wire		[15:0]      clk_div	,//spi时钟分频
	input  	wire                    wr_req	,//读写请求
	output 	wire                    wr_ack	,//读写应答
	input	wire		[7:0]		data_in	,//写数据
	output	wire		[7:0]       data_out//读数据
);

//Reg define
reg                     DCLK_reg	;			//时钟信号寄存器
reg			[7:0]      	MOSI_shift	;			//主机输出从机输入数据寄存器
reg			[7:0]      	MISO_shift	;			//主机输入从机输出数据寄存器
reg			[2:0]      	state		;			//状态寄存器
reg			[2:0]      	next_state	;			//下一个状态寄存器
reg 		[15:0]		clk_cnt		;			//时钟计数器
reg			[4:0]       clk_edge_cnt;			//时钟边沿计数器

localparam				IDLE            = 0;	//空闲状态
localparam				DCLK_EDGE       = 1;	//时钟边沿状态
localparam				DCLK_IDLE       = 2;	//时钟空闲状态
localparam				ACK             = 3;	//应答状态
localparam				LAST_HALF_CYCLE = 4;	//最后半周期状态 
localparam				ACK_WAIT        = 5;	//等待应答状态

assign MOSI = MOSI_shift[7]		;				//主机输出从机输入	
assign data_out = MISO_shift	;				//主机输入从机输出
assign nCS = nCS_ctrl			;				//片选信号	
assign DCLK = DCLK_reg			;				//时钟信号连线			
assign wr_ack = (state == ACK)	;				//应答

//状态机
always@(posedge clk or posedge rst)	begin
	if(rst)
		state <= IDLE;
	else
		state <= next_state;
end
//
always@(*)	begin
	case(state)
		IDLE:
			if(wr_req == 1'b1)//写请求
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

//DCLK时钟控制
always@(posedge clk or posedge rst)	begin
	if(rst)
		DCLK_reg <= 1'b0;
	else if(state == IDLE)//空闲状态时钟保持空闲状态CPOL
		DCLK_reg <= CPOL;
	else if(state == DCLK_EDGE)//传输数据状态时钟翻转
		DCLK_reg <= ~DCLK_reg;			
end

//计数器，用于延时
always@(posedge clk or posedge rst)	begin
	if(rst)
		clk_cnt <= 16'd0;
	else if(state == DCLK_IDLE || state == LAST_HALF_CYCLE)//时钟分频在最前和最后后半周期
		clk_cnt <= clk_cnt + 16'd1;
	else
		clk_cnt <= 16'd0;
end

//
always@(posedge clk or posedge rst)	begin
	if(rst)
		clk_edge_cnt <= 5'd0;
	else if(state == DCLK_EDGE)//时钟边沿计数
		clk_edge_cnt <= clk_edge_cnt + 5'd1;
	else if(state == IDLE)
		clk_edge_cnt <= 5'd0;
end

//采样
always@(posedge clk or posedge rst)	begin
	if(rst)
		MOSI_shift <= 8'd0;
	else if(state == IDLE && wr_req)
		MOSI_shift <= data_in;			
	else if(state == DCLK_EDGE)			
		if(CPHA == 1'b0 && clk_edge_cnt[0] == 1'b1)	//第一个边沿发送
			MOSI_shift <= {MOSI_shift[6:0],MOSI_shift[7]};	
		else if(CPHA == 1'b1 && (clk_edge_cnt != 5'd0 && clk_edge_cnt[0] == 1'b0))//第二个边沿发送
			MOSI_shift <= {MOSI_shift[6:0],MOSI_shift[7]};
end

//
always@(posedge clk or posedge rst)	begin
	if(rst)
		MISO_shift <= 8'd0;
	else if(state == IDLE && wr_req)
		MISO_shift <= 8'h00;
	else if(state == DCLK_EDGE)
		if(CPHA == 1'b0 && clk_edge_cnt[0] == 1'b0)//第一个边沿采样
			MISO_shift <= {MISO_shift[6:0],MISO};
		else if(CPHA == 1'b1 && (clk_edge_cnt[0] == 1'b1))//第二个边沿采样
			MISO_shift <= {MISO_shift[6:0],MISO};
end

endmodule 
