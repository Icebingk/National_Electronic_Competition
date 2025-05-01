module uart_rx#(
	parameter MAX_BPS = 115200			,	// 波特率定义
	parameter CLOCK = 50_000_000		, 	// 系统时钟频率定义
	parameter MAX_1bit = CLOCK / MAX_BPS, 	// 单位的时钟耗费的周期定义
	parameter CHECK_BIT = "None" 			// 是否使用校验位定义
)( 
	input				clk				,	//系统时钟
	input				rst_n			,	//系统复位
	input           	rx				,	//接收数据线
	output          	rx_data_vld		,	//接收数据有效标志
	output   [7:0]		rx_data			,	//接收数据
	output wire 		ready
);								 




localparam  IDLE   = 'b0001,//空闲状态
			START  = 'b0010,//开始状态，接收起始位
			DATA   = 'b0100,//接收数据状态
			CHECK  = 'b1000;//接收校验位状态

reg 	[3:0]	cstate     	;//当前状态
reg		[3:0]	nstate     	;//下一状态

wire			IDLE_START;//控制IDLE到START状态转换
wire    		START_DATA;//控制START到DATA状态转换
wire    		DATA_IDLE; //控制DATA到IDLE状态转换
wire    		DATA_CHECK;//控制DATA到CHECK状态转换
wire    		CHECK_IDLE;//控制CHECK到IDLE状态转换

reg		[8:0]	cnt_baud	   	;//波特率计数
wire			add_cnt_baud	;//波特率计数允许
wire			end_cnt_baud	;//波特率计数结束

reg		[2:0]	cnt_bit	   	;//数据计数
wire			add_cnt_bit	;//数据计数允许
wire			end_cnt_bit	;//数据计数结束

reg		[3:0]	bit_max;//不同状态下要接收的bit数

reg		[7:0]	rx_temp;//接收数据寄存器
reg				rx_check;//校验位寄存器
wire			check_val;//计算接收到的数据的奇偶校验值

reg				rx_r1;//接收数据信号寄存器
reg				rx_r2;//辅助判断开始信号寄存器
wire			rx_nege;//判断接收到的是下检验 

//用于判断是下降沿而不是抖动
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		rx_r1 <= 1;
		rx_r2 <= 1;
		end
	else begin
		rx_r1 <= rx;
		rx_r2 <= rx_r1;
	end
end
//如果是下检验，输出1
assign rx_nege = ~rx_r1 && rx_r2;

//
always @(posedge clk or negedge rst_n)begin 
	if(!rst_n)begin
		cnt_baud <= 'd0;
	end else if(add_cnt_baud)begin //进行单bit的波特率计数
		if(end_cnt_baud)begin //如果计数完成
			cnt_baud <= 'd0;
			end
		else begin 
			cnt_baud <= cnt_baud + 1'd1;
		end 
	end
end 

assign add_cnt_baud = cstate != IDLE;//非空闲状态下，控制波特率计数允许开始
assign end_cnt_baud = add_cnt_baud && cnt_baud == MAX_1bit - 1'd1;//计数完成

//
always @(posedge clk or negedge rst_n)begin 
	if(!rst_n)begin
		cnt_bit <= 'd0;
	end	else if(add_cnt_bit)begin //进行接收的数据计数
		if(end_cnt_bit)begin //如果计数完成
			cnt_bit <= 'd0;
		end	else begin 
			cnt_bit <= cnt_bit + 1'd1;
		end 
	end
end 

assign add_cnt_bit = end_cnt_baud;//波特率计数完成
assign end_cnt_bit = add_cnt_bit && cnt_bit == bit_max -1'd1;//数据计数完成

//不同状态下，要接受的数据位大小
always @(*)begin 
case (cstate)
	IDLE :bit_max = 'd0;
	START:bit_max = 'd1;
	DATA :bit_max = 'd8;
	CHECK:bit_max = 'd1;
	default: bit_max = 'd0;
endcase
end

assign IDLE_START = (cstate == IDLE) && rx_nege;//空闲状态下检测到下检验
assign START_DATA = (cstate == START) && end_cnt_bit;//开始位判断完成
assign DATA_IDLE = (cstate == DATA) && end_cnt_bit && CHECK_BIT == "None";//没有校验位
assign DATA_CHECK = (cstate == DATA) && end_cnt_bit;//有校验位
assign CHECK_IDLE = (cstate == CHECK) && end_cnt_bit;//校验位判断完成

//二段式状态机
always @(posedge clk or negedge rst_n)begin 
	if(!rst_n)begin
		cstate <= IDLE;
	end else begin 
		cstate <= nstate;
	end 
end

//
always @(*) begin
case(cstate)
	IDLE  :begin
		if (IDLE_START) begin
			nstate = START;
		end	else begin
			nstate = cstate;
		end
	end
	START :begin
		if (START_DATA) begin
			nstate = DATA;
		end	else begin
			nstate = cstate;
		end
	end
	DATA  :begin
		if (DATA_IDLE) begin
			nstate = IDLE;
		end	else if (DATA_CHECK) begin
			nstate = CHECK;
		end	else begin
			nstate = cstate;
		end
	end
	CHECK:begin
		if (CHECK_IDLE) begin
			nstate = IDLE;
		end	else begin
			nstate = cstate;
		end
	end
	default : nstate = IDLE;
endcase
end

//
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		rx_check <= 0;
	end else if (cstate == CHECK && cnt_baud == MAX_1bit >>1) begin//接收信号
		rx_check <= rx_r1;
	end
end

assign check_val = (CHECK_BIT == "Odd") ? ~^rx_temp : ^rx_temp;//奇偶校验计算

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		rx_temp <= 0;
	end else if (cstate == DATA && cnt_baud == MAX_1bit >> 1) begin//接收信号
		rx_temp[cnt_bit] <= rx_r1;
	end else begin
		rx_temp <= rx_temp;
	end
end
assign ready = cstate == IDLE;//可接收发送申请

assign rx_data = rx_data_vld?rx_temp:8'd0;//接收数据
assign rx_data_vld  = (CHECK_BIT == "None") ? DATA_IDLE//判断接收到的数据在奇偶校验的情况下是否有效
						:(CHECK_IDLE && (check_val == rx_check)) ? 1
						: 0;

endmodule