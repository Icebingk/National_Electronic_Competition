
module uart_tx
#(
	parameter   MAX_BPS = 115200		,      	//波特率
	parameter   CLOCK = 50_000_000		,    	//系统时钟频率
	parameter   MAX_1bit = CLOCK/MAX_BPS,		//单bit的时钟耗费的周期
	parameter   CHECK_BIT = "None"     			//是否使用校验位
)( 
	input					sys_clk		,		//系统时钟
    input					rst_n		,		//复位信号
    input       [7:0]   	tx_data 	,		//要发送数据
    input               	tx_data_vld	,		//数据有效申请发送
    output  wire        	tx_data_ready,		//发送空闲，可接收申请
    output  reg         	tx           		//tx发送线
);								 


localparam  IDLE   = 'b00001,//空闲状态
            START  = 'b00010,//开始状态，发送起始位
            DATA   = 'b00100,//发送数据状态
            CHECK  = 'b01000,//发送校验位状态
            STOP   = 'b10000;//停止位
				
//二段式状态机
reg 	[4:0]		cstate     		;
reg		[4:0]		nstate     		;
    
wire				IDLE_START		;//控制IDLE到START状态转换
wire 				START_DATA		;//控制START到DATA状态转换
wire 				DATA_STOP		;//控制DATA到STOP状态转换(无校验位)
wire 				DATA_CHECK		;//控制DATA到CHECK状态转换
wire 				CHECK_STOP		;//控制CHECK到STOP状态转换
wire				STOP_IDLE		;//控制STOP到IDLE状态转换

reg	[8:0]			cnt_baud	   	;//单bit波特计数器，因为波特率比系统时钟频率低，所以每个bit都要持续一段时间
wire				add_cnt_baud	;//控制波特率计数器
wire				end_cnt_baud	;//表示波特率计数完成

reg	[2:0]			cnt_bit			;//计算发送的数据个数
wire				add_cnt_bit		;//控制数据计数器
wire				end_cnt_bit		;//表示数据计数器完成

reg 	[3:0]   	bit_max			;//不同状态下要发送的bit数
reg  	[7:0]   	tx_data_r		;//要发送的数据

wire				check_val		;//校验数据是否有效

//控制状态转换
assign IDLE_START = (cstate == IDLE) && tx_data_vld;//空闲状态下有数据需要发送
assign START_DATA = (cstate == START) && end_cnt_bit;//起始位发送完成
assign DATA_STOP = (cstate == DATA) && end_cnt_bit && CHECK_BIT == "None";//没有校验位的情况
assign DATA_CHECK = (cstate == DATA) && end_cnt_bit;//有校验位的情况
assign CHECK_STOP = (cstate ==CHECK) && end_cnt_bit;//校验位发送完成
assign STOP_IDLE = (cstate == STOP) && end_cnt_bit;//停止位发送完成

always @(posedge sys_clk or negedge rst_n)begin 
	if(!rst_n)begin
		cnt_baud <= 'd0;
	end else if(add_cnt_baud)begin //如果需要波特率计数
      	if(end_cnt_baud)begin//如果计数完成
			cnt_baud <= 'd0;
		end else begin//否则自增 
         cnt_baud <= cnt_baud + 1'd1;
        end 
      end
   end 
    
assign add_cnt_baud = cstate != IDLE;//非空闲状态下，控制波特率计数允许开始
assign end_cnt_baud = add_cnt_baud && cnt_baud == MAX_1bit - 1'd1;//波特率计数结束，只保持一个周期
    
//
always @(posedge sys_clk or negedge rst_n)begin 
	if(!rst_n)begin
		cnt_bit <= 'd0;
		end 
	else if(add_cnt_bit)begin //进行发送的数据计数
		if(end_cnt_bit)begin //如果计数完成
			cnt_bit <= 'd0;
		end else begin 
			cnt_bit <= cnt_bit + 1'd1;
		end 
	end
end 
    
assign add_cnt_bit = end_cnt_baud;//波特率计数完成，表示一个数据位发送完成允许计数+1
assign end_cnt_bit = add_cnt_bit && cnt_bit == bit_max -1'd1;//发送的数据完成，结束计数
    
//不同状态下要发送的bit数
always @(*)begin 
	case (cstate)
		IDLE :bit_max = 'd0;
		START:bit_max = 'd1;
		DATA :bit_max = 'd8;
		CHECK:bit_max = 'd1;
		STOP :bit_max = 'd1;
		default: bit_max = 'd0;
	endcase
end


//状态机转换
always @(posedge sys_clk or negedge rst_n)begin 
   	if(!rst_n)begin
		cstate <= IDLE;
	end else begin 
		cstate <= nstate;
	end 
end
    
//状态机控制
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
			if (DATA_CHECK) begin
				nstate = CHECK;
			end else if (DATA_STOP) begin
				nstate = STOP;
			end	else begin
				nstate = cstate;
			end
		end
		CHECK :begin
			if (CHECK_STOP) begin
				nstate = STOP;
			end	else begin
				nstate = cstate;
			end
		end
		STOP  :begin
			if (STOP_IDLE) begin
				nstate = IDLE;
			end	else begin
				nstate = cstate;
			end
		end
		default : nstate = cstate;
	endcase
end

//要发送的数据
always @(posedge sys_clk or negedge rst_n) begin
	if (!rst_n) begin
		tx_data_r <= 'd0;
	end else if (tx_data_vld) begin
		tx_data_r <= tx_data;
	end	else begin
		tx_data_r <= tx_data_r;
	end
end
    
//奇偶校验
assign check_val = (CHECK_BIT == "Odd") ? ~^tx_data_r : ^tx_data_r;
    
//数据串行发送
always @(*)begin 
	case (cstate)
		IDLE : tx = 1'b1;//空闲拉高
		START: tx = 1'b0;//开始拉低
		DATA : tx = tx_data_r[cnt_bit];//发送数据
		CHECK: tx = check_val;//如果有校验
		STOP : tx = 1'b1;//停止拉高
	default: tx = 1'b1;
	endcase
end            

assign tx_data_ready = cstate == IDLE;//可接收发送申请
     
endmodule
