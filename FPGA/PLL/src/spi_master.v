module spi_master(
    input  	wire                   			clk		,//系统时钟	
    input  	wire                   			rst_n	,//系统复位信号
    input	wire	[14:0]				    clk_div	,//spi时钟分频
    input  	wire                   			wr_req	,//写请求
    output 	wire                   			wr_ack	,//写应答
    input	wire	[32-1:0]				data_in	,//写数据 (32位)
    output	wire	[32-1:0]       			data_out,//读数据 (32位)
    
    output 	wire                   			nCS		,//片选信号
    output 	wire                   			DCLK	,//时钟信号
    output 	wire                   			MOSI	,//主机输出从机输入
    input  	wire                   			MISO	,//主机输入从机输出
    input  	wire                   			CPOL	,//时钟极性（0：高电平有效，1：低电平有效）
    input  	wire                   			CPHA	 //时钟相位（0：第一个边沿采样，1：第二个边沿采样）
);

//Reg define
reg             DCLK_reg	;			//时钟信号寄存器
reg             nCS_reg     ;           //片选信号寄存器
reg	[32-1:0] 	MOSI_shift	;			//主机输出从机输入数据寄存器 (32位)
reg	[32-1:0] 	MISO_shift	;			//主机输入从机输出数据寄存器 (32位)
reg	[3-1:0]		state		;			//状态寄存器
reg	[3-1:0]		next_state	;			//下一个状态寄存器
reg [14:0]	    clk_cnt		;			//时钟计数器
reg	[6-1:0] 	clk_edge_cnt;			//时钟边沿计数器 (6位以支持32位数据传输)
reg [14:0]      nCS_cnt     ;           //片选保持计数器

localparam				IDLE            = 0,	//空闲状态
                        DCLK_IDLE       = 1,	//时钟空闲状态
                        DCLK_EDGE       = 2,	//时钟边沿状态
                        LAST_HALF_CYCLE = 3,	//最后半周期状态 
                        CS_HIGH_HOLD    = 4,    //片选高电平保持状态
                        ACK             = 5,	//应答状态
                        ACK_WAIT        = 6;	//等待应答状态

assign MOSI = MOSI_shift[32-1];		            //主机输出从机输入 (最高位)
assign data_out = MISO_shift	;				//主机输入从机输出
assign nCS = nCS_reg			;				//片选信号	
assign DCLK = DCLK_reg			;				//时钟信号连线			
assign wr_ack = (state == ACK)	;				//应答

//片选信号控制
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        nCS_reg <= 1'b1;  //复位时片选无效(高)
    else if(state == IDLE && wr_req)
        nCS_reg <= 1'b0;  //开始传输时片选有效(低)
    else if(state == LAST_HALF_CYCLE && clk_cnt == clk_div)
        nCS_reg <= 1'b1;  //传输结束时片选无效(高)
end

//状态转换
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
            if(clk_cnt == clk_div)//时钟分频，度过空闲状态
                next_state <= DCLK_EDGE;
            else
                next_state <= DCLK_IDLE;
        DCLK_EDGE: 
            if(clk_edge_cnt == 6'd63)//传输数据状态，计数时钟边沿 (63以支持32位数据)
                next_state <= LAST_HALF_CYCLE;
            else
                next_state <= DCLK_IDLE;	
        LAST_HALF_CYCLE:
            if(clk_cnt == clk_div)//时钟分频，时钟有效时，时钟边沿计数
                next_state <= CS_HIGH_HOLD;
            else
                next_state <= LAST_HALF_CYCLE; 	
        CS_HIGH_HOLD:
            if(nCS_cnt >= clk_div)//保持片选高电平1个SCL周期
                next_state <= ACK;
            else
                next_state <= CS_HIGH_HOLD;
        ACK:
            next_state <= ACK_WAIT;//直接进入ACK_WAIT状态
        ACK_WAIT:
            next_state <= IDLE;//应答等待状态
        default:
            next_state <= IDLE;
    endcase
end

//片选高电平保持计数器
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        nCS_cnt <= {15{1'b0}};
    else if(state == CS_HIGH_HOLD)
        nCS_cnt <= nCS_cnt + 'd1;
    else
        nCS_cnt <= {15{1'b0}};
end

//时钟信号控制
always@(posedge clk or negedge rst_n)	begin
    if(!rst_n)
        DCLK_reg <= 'b0;
    else if(state == IDLE)//空闲状态时钟保持空闲状态CPOL
        DCLK_reg <= CPOL;
    else if(state == DCLK_EDGE)//传输数据状态时钟翻转
        DCLK_reg <= ~DCLK_reg;			
end

//时钟分频计数器
always@(posedge clk or negedge rst_n)	begin
    if(!rst_n)
        clk_cnt <= {14{1'b0}};
    else if(state == DCLK_IDLE || state == LAST_HALF_CYCLE)//时钟分频在最前和最后后半周期
        clk_cnt <= clk_cnt + 'd1;
    else
        clk_cnt <= {14{1'b0}};
end

//时钟边沿计数器
always@(posedge clk or negedge rst_n)	begin
    if(!rst_n)
        clk_edge_cnt <= {6{1'b0}}; // 6位
    else if(state == DCLK_EDGE)//时钟边沿计数
        clk_edge_cnt <= clk_edge_cnt + 'd1;
    else if(state == IDLE)
        clk_edge_cnt <= {6{1'b0}}; // 6位
end

//发送数据移位寄存器
always@(posedge clk or negedge rst_n)	begin
    if(!rst_n)
        MOSI_shift <= {32{1'b0}}; // 32位
    else if(state == IDLE && wr_req)
        MOSI_shift <= data_in;			
    else if(state == DCLK_EDGE)			
        if(CPHA == 1'b0 && clk_edge_cnt[0] == 'b1)	//下降沿变化
            MOSI_shift <= {MOSI_shift[32-2:0],MOSI_shift[32-1]};	// 32位
        else if(CPHA == 1'b1 && (clk_edge_cnt != {6{1'b0}} && clk_edge_cnt[0] == 'b0))//上升沿变化
            MOSI_shift <= {MOSI_shift[32-2:0],MOSI_shift[32-1]};  // 32位
end

//接收数据移位寄存器
always@(posedge clk or negedge rst_n)	begin
    if(!rst_n)
        MISO_shift <= {32{1'b0}}; // 32位
    else if(state == IDLE && wr_req)
        MISO_shift <= {32{1'b0}}; // 32位
    else if(state == DCLK_EDGE)
        if(CPHA == 'b0 && clk_edge_cnt[0] == 'b0)//上升沿采样
            MISO_shift <= {MISO_shift[32-2:0],MISO}; // 32位
        else if(CPHA == 'b1 && (clk_edge_cnt[0] == 'b1))//下降沿变化
            MISO_shift <= {MISO_shift[32-2:0],MISO}; // 32位
end

endmodule