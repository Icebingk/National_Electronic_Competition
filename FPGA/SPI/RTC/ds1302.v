module ds1302(
	input	wire           		clk				,//时钟信号
	input	wire           		rst				,//复位信号
	
	output	wire          		ds1302_ce		,//片选信号
	output	wire          		ds1302_sclk		,//DS1302的时钟信号
	inout	wire           		ds1302_io		,//将MISO和MOSI合并为一个端口
	
	input   wire        		write_time_req	,//写时间请求
	output  wire        		write_time_ack	,//写时间应答
	input	wire	[7:0]      	write_second	,//写秒
	input	wire	[7:0]      	write_minute	,//写分
	input	wire	[7:0]      	write_hour		,//写时
	input	wire	[7:0]      	write_date		,//写日
	input	wire	[7:0]      	write_month		,//写月
	input	wire	[7:0]      	write_week		,//写星期
	input	wire	[7:0]      	write_year		,//写年
	
	input   wire        		read_time_req	,//读时间请求
	output  wire        		read_time_ack	,//读时间应答
	output 	reg		[7:0] 		read_second		,//读秒
	output 	reg		[7:0] 		read_minute		,//读分
	output 	reg		[7:0] 		read_hour		,//读时
	output 	reg		[7:0] 		read_date		,//读日
	output 	reg		[7:0] 		read_month		,//读月
	output 	reg		[7:0] 		read_week		,//读星期
	output 	reg		[7:0] 		read_year		 //读年

);
//状态机状态
localparam S_IDLE         =  0	;//空闲状态，等待读/写时间请求
localparam S_WR_WP        =  1	;//写保护状态，清除写保护才能写入时间，否则只能读取时间
localparam S_WR_SEC       =  2	;//写秒寄存器状态
localparam S_WR_MIN       =  3	;//写分钟寄存器状态
localparam S_WR_HOUR      =  4	;//写小时寄存器状态
localparam S_WR_DATE      =  5	;//写日期寄存器状态
localparam S_WR_MON       =  6	;//写月份寄存器状态
localparam S_WR_WEEK      =  7	;//写星期寄存器状态
localparam S_WR_YEAR      =  8	;//写年份寄存器状态
localparam S_RD_SEC       =  9	;//读取秒寄存器状态
localparam S_RD_MIN       = 10	;//读取分钟寄存器状态
localparam S_RD_HOUR      = 11	;//读取小时寄存器状态
localparam S_RD_MON       = 12	;//读取月份寄存器状态
localparam S_RD_WEEK      = 13	;//读取星期寄存器状态
localparam S_RD_YEAR      = 14	;//读取年份寄存器状态
localparam S_RD_DATE      = 15	;//读取日期寄存器状态
localparam S_ACK          = 16	;//读写操作完成应答状态

//reg define
reg					[4:0] 		state, next_state	;//状态机状态
reg					[7:0] 		read_addr			;//读地址
reg					[7:0] 		write_addr			;//写地址	
reg					[7:0] 		write_data			;//写数据	
reg 							cmd_write			;//写命令			
reg 							cmd_read			;//读命令
//wire define
wire				[7:0] 		read_data			;//读数据输出	
wire 							cmd_read_ack		;//读命令应答	
wire 							cmd_write_ack		;//写命令应答	

//读写命令应答信号，仅表示命令是否执行完成，不表示数据是否正确
assign write_time_ack 	= (state == S_ACK);
assign read_time_ack 	= (state == S_ACK);

//控制写命令
always@(posedge clk or posedge rst)	begin
	if(rst)
		cmd_write <= 1'b0;
	else if(cmd_write_ack)
		cmd_write <= 1'b0;
	else
		case(state)
			S_WR_WP,
			S_WR_SEC,
			S_WR_MIN,
			S_WR_HOUR,
			S_WR_DATE,
			S_WR_MON,
			S_WR_WEEK,
			S_WR_YEAR:
			cmd_write <= 1'b1;
		endcase
end

//控制读命令
always@(posedge clk or posedge rst)	begin
	if(rst)
		cmd_read <= 1'b0;
	else if(cmd_read_ack)
		cmd_read <= 1'b0;
	else
		case(state)
			S_RD_SEC,
			S_RD_MIN,
			S_RD_HOUR,
			S_RD_DATE,
			S_RD_MON,
			S_RD_WEEK,
			S_RD_YEAR:
				cmd_read <= 1'b1;
		endcase
end

//如果在读秒状态，且读命令应答信号有效，则将读取的数据赋值给read_second
always@(posedge clk or posedge rst)	begin
	if(rst)
		read_second <= 8'h00;
	else if(state == S_RD_SEC && cmd_read_ack)
		read_second <= read_data;
end

//如果在读分状态，且读命令应答信号有效，则将读取的数据赋值给read_minute
always@(posedge clk or posedge rst)	begin
	if(rst)
		read_minute <= 8'h00;
	else if(state == S_RD_MIN && cmd_read_ack)
		read_minute <= read_data;
end

//如果在读时状态，且读命令应答信号有效，则将读取的数据赋值给read_hour
always@(posedge clk or posedge rst)	begin
	if(rst)
		read_hour <= 8'h00;
	else if(state == S_RD_HOUR && cmd_read_ack)
		read_hour <= read_data;
end

//如果在读日期状态，且读命令应答信号有效，则将读取的数据赋值给read_date
always@(posedge clk or posedge rst)	begin
	if(rst)
		read_date <= 8'h00;
	else if(state == S_RD_DATE && cmd_read_ack)
		read_date <= read_data;
end

//如果在读月份状态，且读命令应答信号有效，则将读取的数据赋值给read_month
always@(posedge clk or posedge rst)	begin
	if(rst)
		read_month <= 8'h00;
	else if(state == S_RD_MON && cmd_read_ack)
		read_month <= read_data;
end

//如果在读星期状态，且读命令应答信号有效，则将读取的数据赋值给read_week
always@(posedge clk or posedge rst)	begin
	if(rst)
		read_week <= 8'h00;
	else if(state == S_RD_WEEK && cmd_read_ack)
		read_week <= read_data;
end

//如果在读年份状态，且读命令应答信号有效，则将读取的数据赋值给read_year
always@(posedge clk or posedge rst)	begin
	if(rst)
		read_year <= 8'h00;
	else if(state == S_RD_YEAR && cmd_read_ack)
		read_year <= read_data;
end

//在读不同时间状态时，选择不同的地址
always@(posedge clk or posedge rst)	begin
	if(rst)
		read_addr <= 8'h00;
	else
		case(state)
				S_RD_SEC:
					read_addr <= 8'h81;
				S_RD_MIN:
					read_addr <= 8'h83;
				S_RD_HOUR:
					read_addr <= 8'h85;
				S_RD_DATE:
					read_addr <= 8'h87;
				S_RD_MON:
					read_addr <= 8'h89;
				S_RD_WEEK:
					read_addr <= 8'h8b;
				S_RD_YEAR:
					read_addr <= 8'h8d;
			default:
				read_addr <= read_addr;
		endcase
end

//控制写时间状态，根据不同的状态选择不同的地址和数据
always@(posedge clk or posedge rst)	begin
	if(rst)
		begin
			write_addr <= 8'h00;
			write_data <= 8'h00;
		end
	else
		case(state)
			S_WR_WP:
				begin
					write_addr <= 8'h8e;
					write_data <= 8'h00;
				end
			S_WR_SEC:
				begin
					write_addr <= 8'h80;
					write_data <= write_second;
				end
			S_WR_MIN:
				begin
					write_addr <= 8'h82;
					write_data <= write_minute;
				end
			S_WR_HOUR:
				begin
					write_addr <= 8'h84;
					write_data <= write_hour;
				end
			S_WR_DATE:
				begin
					write_addr <= 8'h86;
					write_data <= write_date;
				end
			S_WR_MON:
				begin
					write_addr <= 8'h88;
					write_data <= write_month;
				end
			S_WR_WEEK:
				begin
					write_addr <= 8'h8a;
					write_data <= write_week;
				end
			S_WR_YEAR:
				begin
					write_addr <= 8'h8c;
					write_data <= write_year;
				end
			default:
				begin
					write_addr <= 8'h00;
					write_data <= 8'h00;
				end
		endcase
end

//状态机
always@(posedge clk or posedge rst)	begin
	if(rst)
		state <= S_IDLE;
	else
		state <= next_state;
end

//状态变化
always@(*)	begin
	case(state)
		S_IDLE:
			if(write_time_req)
				next_state <= S_WR_WP;
			else if(read_time_req)
				next_state <= S_RD_SEC;
			else
				next_state <= S_IDLE;
		S_WR_WP:
			if(cmd_write_ack)
				next_state <= S_WR_SEC;
			else
				next_state <= S_WR_WP;
		S_WR_SEC:
			if(cmd_write_ack)
				next_state <= S_WR_MIN;
			else
				next_state <= S_WR_SEC;
		S_WR_MIN:
			if(cmd_write_ack)
				next_state <= S_WR_HOUR;
			else
				next_state <= S_WR_MIN;
		S_WR_HOUR:
			if(cmd_write_ack)
				next_state <= S_WR_DATE;
			else
				next_state <= S_WR_HOUR;
		S_WR_DATE:
			if(cmd_write_ack)
				next_state <= S_WR_MON;
			else
				next_state <= S_WR_DATE;
		S_WR_MON:
			if(cmd_write_ack)
				next_state <= S_WR_WEEK;
			else
				next_state <= S_WR_MON;
		S_WR_WEEK:
			if(cmd_write_ack)
				next_state <= S_WR_YEAR;
			else
				next_state <= S_WR_WEEK;
		S_WR_YEAR:
			if(cmd_write_ack)
				next_state <= S_ACK;
			else
				next_state <= S_WR_YEAR;
		S_RD_SEC:
			if(cmd_read_ack)
				next_state <= S_RD_MIN;
			else
				next_state <= S_RD_SEC;
		S_RD_MIN:
			if(cmd_read_ack)
				next_state <= S_RD_HOUR;
			else
				next_state <= S_RD_MIN;
		S_RD_HOUR:
			if(cmd_read_ack)
				next_state <= S_RD_DATE;
			else
				next_state <= S_RD_HOUR;
		S_RD_DATE:
			if(cmd_read_ack)
				next_state <= S_RD_MON;
			else
				next_state <= S_RD_DATE;
		S_RD_MON:
			if(cmd_read_ack)
				next_state <= S_RD_WEEK;
			else
				next_state <= S_RD_MON;
		S_RD_WEEK:
			if(cmd_read_ack)
				next_state <= S_RD_YEAR;
			else
				next_state <= S_RD_WEEK;
		S_RD_YEAR:
			if(cmd_read_ack)
				next_state <= S_ACK;
			else
				next_state <= S_RD_YEAR;
		S_ACK:
			next_state <= S_IDLE;
		default:
			next_state <= S_IDLE;
	endcase
end

//ds1302 module
ds1302_io ds1302_io_m0(
	.clk					(clk)			,
	.rst					(rst)			,
	.ds1302_ce				(ds1302_ce)		,
	.ds1302_sclk			(ds1302_sclk)	,
	.ds1302_io				(ds1302_io)		,
	.cmd_read				(cmd_read)		,
	.cmd_write				(cmd_write)		,
	.cmd_read_ack			(cmd_read_ack)	,
	.cmd_write_ack			(cmd_write_ack)	,
	.read_addr				(read_addr)		,
	.write_addr				(write_addr)	,
	.read_data				(read_data)		,
	.write_data				(write_data)
);

endmodule
