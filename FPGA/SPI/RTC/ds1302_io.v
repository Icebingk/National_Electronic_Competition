module ds1302_io(
	input	wire           		clk				,//时钟信号
	input   wire        		rst				,//复位信号
	output  wire        		ds1302_ce		,//片选信号
	output	wire        		ds1302_sclk		,//DS1302的时钟信号
	inout	wire				ds1302_io		,//将MISO和MOSI合并为一个端口
	input	wire           		cmd_read		,//读命令
	input	wire           		cmd_write		,//写命令	
	output	wire          		cmd_read_ack	,//读命令应答
	output	wire          		cmd_write_ack	,//写命令应答
	input	wire	[7:0]      	read_addr		,//读地址
	input	wire	[7:0]      	write_addr		,//写地址	
	input	wire	[7:0]      	write_data		,//写数据	
	output	reg		[7:0] 		read_data		 //读数据输出
);

// Reg define
reg					[3:0] 		state, next_state	;//状态机状态
reg					[19:0] 		delay_cnt			;//延时计数，用于模拟SPI的时序
reg 							wr_req				;//读写请求
reg					[7:0] 		send_data			;//发送的数据
reg 							CS_reg				;//片选信号						
reg 							ds1302_io_dir		;//判断IO的方向
// Wire define
wire 							DCLK				;//SPI的时钟信号
wire 							MOSI				;//SPI的主机输出从机输入
wire 							MISO				;//SPI的主机输入从机输出
wire				[7:0] 		data_rec			;//SPI输出的数据
wire 							wr_ack				;//读写应答

//状态
localparam 						S_IDLE         =  0	;//空闲状态
localparam 						S_CE_HIGH      =  1	;//片选信号高电平
localparam 						S_READ         =  2	;//读状态
localparam 						S_READ_ADDR    =  3	;//获取读地址
localparam 						S_READ_DATA    =  4	;//返回读数据
localparam 						S_WRITE        =  5	;//写状态
localparam 						S_WRITE_ADDR   =  6	;//获取写地址
localparam 						S_WRITE_DATA   =  7	;//写入数据
localparam 						S_CE_LOW       =  8	;//片选信号低电平
localparam 						S_ACK          =  9	;//应答


assign ds1302_io = ~ds1302_io_dir ? MOSI : 1'bz;//如果是读数据，那么ds1302_io是MOSI，否则是高阻态，交给从机输入	
assign MISO = ds1302_io;

assign ds1302_sclk = DCLK;//DS1302的时钟信号
// 读写命令应答信号
assign cmd_read_ack = (state == S_ACK);
assign cmd_write_ack = (state == S_ACK);

// 状态机
always@(posedge clk or posedge rst)	begin
	if(rst)
		state <= S_IDLE;
	else
		state <= next_state;
end

// 
always@(*)	begin
	case(state)
		S_IDLE:
			if(cmd_read || cmd_write)//读写命令，将片选信号拉高
				next_state <= S_CE_HIGH;
			else
				next_state <= S_IDLE;
		S_CE_HIGH://片选信号高电平有效，延时后进入读写状态
			if(delay_cnt == 20'd255)
				next_state <= cmd_read ? S_READ : S_WRITE;
			else
				next_state <= S_CE_HIGH;
		S_READ://读状态，先获取读地址
			next_state <= S_READ_ADDR;
		S_READ_ADDR://获取读地址后，进入读数据状态
			if(wr_ack)
				next_state <= S_READ_DATA;
			else
				next_state <= S_READ_ADDR;
		S_READ_DATA://读数据状态，读完后进入应答状态
			if(wr_ack)
				next_state <= S_ACK;
			else
				next_state <= S_READ_DATA;
		S_WRITE://写状态，先获取写地址
			next_state <= S_WRITE_ADDR;
		S_WRITE_ADDR://获取写地址后，进入写数据状态
			if(wr_ack)
				next_state <= S_WRITE_DATA;
			else
				next_state <= S_WRITE_ADDR;
		S_WRITE_DATA://写数据状态，写完后进入应答状态
			if(wr_ack)
				next_state <= S_ACK;
			else
				next_state <= S_WRITE_DATA;
		S_ACK://应答状态，延时后片选信号拉低
			next_state <= S_CE_LOW;
		S_CE_LOW://片选信号拉低，延时后进入空闲状态
			if(delay_cnt == 20'd255)
				next_state <= S_IDLE;
			else
				next_state <= S_CE_LOW;
		default:next_state <= S_IDLE;
	endcase
end

//控制片选信号
always@(posedge clk or posedge rst)	begin
	if(rst)
		CS_reg <= 1'b0;
	else if(state == S_CE_HIGH)
		CS_reg <= 1'b1;
	else if(state == S_CE_LOW)
		CS_reg <= 1'b0;
end

//在读写状态时，延时
always@(posedge clk or posedge rst)	begin
	if(rst)
		delay_cnt <= 20'd0;
	else if(state == S_CE_HIGH || state == S_CE_LOW)
		delay_cnt <= delay_cnt + 20'd1;
	else
		delay_cnt <= 20'd0;
end

//控制SPI的读写请求
always@(posedge clk or posedge rst)	begin
	if(rst)
		wr_req <= 1'b0;
	else if(wr_ack)
		wr_req <= 1'b0;
	else if(state == S_READ_ADDR || state == S_READ_DATA || state == S_WRITE_ADDR || state == S_WRITE_DATA)
		wr_req <= 1'b1;	
end

//如果是读数据，那么ds1302_io是输入，否则一直保持输出
always@(posedge clk or posedge rst)	begin
	if(rst)
		ds1302_io_dir <= 1'b0;
	else
		ds1302_io_dir <= (state == S_READ_DATA);
end

//如果是读数据，并且有读应答，那么将读到的数据赋值给read_data，高低位反转
always@(posedge clk or posedge rst)	begin
	if(rst)
		read_data <= 8'h00;
	else if(state == S_READ_DATA && wr_ack)
		read_data <= {data_rec[0],data_rec[1],data_rec[2],data_rec[3],data_rec[4],data_rec[5],data_rec[6],data_rec[7]};	//把读到的数据高低位反转，因为DS是先读的是低位
end

//在写数据状态，将写数据赋值给send_data
always@(posedge clk or posedge rst)	begin
	if(rst)
		send_data <= 8'h00;
	else begin 
		if(state == S_READ_ADDR)
			send_data <= {1'b1,read_addr[1],read_addr[2],read_addr[3],read_addr[4],read_addr[5],read_addr[6],1'b1};
		else if(state == S_WRITE_ADDR)
			send_data <= {1'b0,write_addr[1],write_addr[2],write_addr[3],write_addr[4],write_addr[5],write_addr[6],1'b1};
		else if(state == S_WRITE_DATA)
			send_data <= {write_data[0],write_data[1],write_data[2],write_data[3],write_data[4],write_data[5],write_data[6],write_data[7]};
	end
end

//spi module
spi_master spi_master_m0(
	.clk			(clk)			,
	.rst			(rst)			,
	.nCS			(ds1302_ce)		,
	.DCLK			(DCLK)			,
	.MOSI			(MOSI)			,
	.MISO			(MISO)			,
	.CPOL			(1'b0)			,
	.CPHA			(1'b0)			,
	.nCS_ctrl		(CS_reg)		,
	.clk_div		(16'd50)		,
	.wr_req			(wr_req)		,
	.wr_ack			(wr_ack)		,
	.data_in		(send_data)		,
	.data_out		(data_rec)
);
endmodule
