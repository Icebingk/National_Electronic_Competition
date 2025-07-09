module ds1302_test(
	input	wire			clk			,
	input	wire       		rst			,

	output	wire      		ds1302_ce	,
	output	wire      		ds1302_sclk	,
	inout   wire			ds1302_io	,
	
	output	wire	[7:0]	read_second	,//读秒
	output	wire	[7:0] 	read_minute	,//读分
	output	wire	[7:0] 	read_hour	,//读时
	output	wire	[7:0] 	read_date	,//读日
	output	wire	[7:0] 	read_month	,//读月
	output	wire	[7:0] 	read_week	,//读星期
	output	wire	[7:0] 	read_year	 //读年
);

reg					[2:0] 	state,next_state	;//状态机状态
reg 						write_time_req		;//写时间请求
reg 						read_time_req		;//读时间请求
reg					[7:0] 	write_second_reg	;//写秒
reg					[7:0] 	write_minute_reg	;//写分
reg					[7:0] 	write_hour_reg		;//写时
reg					[7:0] 	write_date_reg		;//写日
reg					[7:0] 	write_month_reg		;//写月
reg					[7:0] 	write_week_reg		;//写星期
reg					[7:0] 	write_year_reg		;//写年

wire 						write_time_ack		;//写时间应答
wire 						read_time_ack		;//读时间应答
wire 						CH					;//时钟电路的CH引脚，是否启动或停止

localparam 					S_IDLE    	=    0	;
localparam 					S_READ    	=    1	;
localparam 					S_WRITE   	=    2	;
localparam 					S_READ_CH 	=    3	;
localparam 					S_WRITE_CH 	=    4	;
localparam 					S_WAIT     	=    5	;


assign CH = read_second[7];	

//如果写完时间，将写时间请求置0，如果初始化写时间状态，将写时间请求置1
always@(posedge clk)	begin
	if(write_time_ack)
		write_time_req <= 1'b0;
	else if(state == S_WRITE_CH)
		write_time_req <= 1'b1;
end

//如果读完时间，将读时间请求置0，判断是否读时间状态，将读时间请求置1
always@(posedge clk)	begin
	if(read_time_ack)
		read_time_req <= 1'b0;
	else if(state == S_READ || state == S_READ_CH)
		read_time_req <= 1'b1;
end

//状态机
always@(posedge clk or posedge rst)	begin
	if(rst)
		state <= S_IDLE;
	else
		state <= next_state;	
end

//控制写入的时间
always@(posedge clk or posedge rst)	begin
	if(rst)	begin
		write_second_reg <= 8'h00;
		write_minute_reg <= 8'h00;
		write_hour_reg   <= 8'h00;
		write_date_reg   <= 8'h00;
		write_month_reg  <= 8'h00;
		write_week_reg   <= 8'h00;
		write_year_reg   <= 8'h00;
	end
	else if(state == S_WRITE_CH) begin
		write_second_reg <= 8'h56;
		write_minute_reg <= 8'h59;
		write_hour_reg   <= 8'h11;
		write_date_reg   <= 8'h09;
		write_month_reg  <= 8'h08;
		write_week_reg   <= 8'h00;
		write_year_reg   <= 8'h24;
	end
end

//
always@(*)	begin
	case(state)		
		S_IDLE:
				next_state <= S_READ_CH;
		S_READ_CH://读取CH引脚，判断是否启动或停止，1表示停止，要初始化并且开始时钟
			if(read_time_ack)
				next_state <= CH ? S_WRITE_CH : S_READ;
			else
				next_state <= S_READ_CH;
		S_WRITE_CH://初始化并且开始时钟
			if(write_time_ack)
				next_state <= S_WAIT;
			else
				next_state <= S_WRITE_CH;
		S_WAIT://等待时钟初始化完成
			next_state <= S_READ;
		S_READ://读时间
			if(read_time_ack)
				next_state <= S_IDLE;
			else
				next_state <= S_READ;
		default:
			next_state <= S_IDLE;
	endcase
end

ds1302 ds1302_m0(
	.rst				(rst)				,
	.clk				(clk)				,
	.ds1302_ce			(ds1302_ce)			,
	.ds1302_sclk		(ds1302_sclk)		,
	.ds1302_io			(ds1302_io)			,
	.write_time_req		(write_time_req)	,
	.write_time_ack		(write_time_ack)	,
	.write_second		(write_second_reg)	,
	.write_minute		(write_minute_reg)	,
	.write_hour			(write_hour_reg)	,
	.write_date			(write_date_reg)	,
	.write_month		(write_month_reg)	,
	.write_week			(write_week_reg)	,
	.write_year			(write_year_reg)	,
	.read_time_req		(read_time_req)		,
	.read_time_ack		(read_time_ack)		,
	.read_second		(read_second)		,
	.read_minute		(read_minute)		,
	.read_hour			(read_hour)			,
	.read_date			(read_date)			,
	.read_month			(read_month)		,
	.read_week			(read_week)			,
	.read_year			(read_year)
	
);

endmodule 
