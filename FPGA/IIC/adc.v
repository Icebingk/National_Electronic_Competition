module adc(
	input	wire					clk		   			,// 系统时钟
	input	wire					rst_n	   			,// 复位信号
	input   wire					wr_req      		,// 写请求信号
	input   wire					rd_req      		,// 读请求信号
	input   wire	[6:0]			device_id   		,// 设备ID
	input   wire    [7:0]			reg_addr   			,// 寄存器地址
	input   wire					reg_addr_vld		,// 寄存器地址有效信号
	input   wire    [7:0]			wr_data     		,// 写数据
	input   wire					wr_data_vld 		,// 写数据有效信号
	output  wire    [7:0]			rd_data_adc    		,// 读数据
	output  wire					rd_data_vld 		,// 读数据有效信号
	output  wire					ready       		,// 读写完成信号

	output  wire    [4:0]			cmd_adc		  		,// 指令寄存器
	output  wire					cmd_vld_adc	  		,// 指令有效信号
	output  wire    [7:0]           op_wr_data_adc		,// 发送数据
	input   wire    [7:0]			op_rd_data_adc		,// 读数据
	input   wire					op_rd_data_vld_adc	,// 读数据有效信号
	input   wire                    rev_ack        		,// 应答信号
	input   wire					done_adc         	 // 读写完成信号
);

//para define
`define     	START_BIT   5'b00001// 开始位指令
`define     	WRITE_BIT   5'b00010// 写数据指令
`define     	READ_BIT    5'b00100// 读数据指令
`define     	STOP_BIT    5'b01000// 停止位指令
`define     	ACK_BIT     5'b10000// 应答指令
//状态机
localparam  	IDLE     = 	6'b000001,
				WR_REQ   = 	6'b000010,
				WR_WAIT  = 	6'b000100,
				RD_REQ   = 	6'b001000,
				RD_WAIT  = 	6'b010000,
				DONE     = 	6'b100000;
//wire define				
reg [7:0] 	adc_mdata_r		;// 读取的低8位数据
reg [7:0] 	adc_ldata_r		;// 读取的高8位数据

// 状态变换控制
wire    	IDLE_WR_REQ     ;
wire    	IDLE_RD_REQ     ;
wire    	WR_REQ_WR_WAIT  ;
wire    	RD_REQ_RD_WAIT  ;
wire    	WR_WAIT_WR_REQ  ;
wire    	WR_WAIT_DONE    ;
wire    	RD_WAIT_RD_REQ  ;
wire    	RD_WAIT_DONE    ;
wire    	DONE_IDLE       ;

wire		done			;// 一次byte传输完成
wire		add_cnt_byte	;// 接收done信号，计数
wire		end_cnt_byte	;// 计数结束信号，完成发送
wire [7:0]	op_rd_data  	;

//reg define
reg	[7:0]	op_wr_data  	;
reg	[7:0] 	device_id_r  	;// 设备ID+读写位
reg [7:0] 	device_id_w  	;// 设备ID+读写位
reg	[5:0]	cstate     		;// 二段式状态机
reg	[5:0]	nstate     		;
reg	[4:0]	cmd				;// 指令寄存器
reg			cmd_vld			;// 指令有效信号
reg	[7:0]	addr_r   		;// 读写地址寄存器//
reg			wr_req_r		;// 写申请寄存器，用于消抖
reg			rd_req_r		;// 读申请寄存器，用于消抖
reg	[2:0]	cnt_byte	   	;// 读写byte计数器
reg	[2:0]	num 			;// 不同状态下要读写的byte数

//端口连线
////output
assign op_wr_data_adc = op_wr_data;// 发送数据
assign cmd_adc = cmd;// 指令寄存器
assign cmd_vld_adc = cmd_vld;// 指令有效信号
////input
assign done = done_adc;// 读写完成信号
assign op_rd_data = op_rd_data_adc;// 读数据
assign rd_data_vld = op_rd_data_vld_adc;// 读数据有效信号

assign ready = cstate == IDLE;// 读写完成信号
assign add_cnt_byte = done;// IIC写完一个byte后，计数
assign end_cnt_byte = add_cnt_byte && cnt_byte == num - 1;
assign IDLE_WR_REQ    = (cstate == IDLE)    && wr_req_r;// 空闲状态下，写请求
assign IDLE_RD_REQ    = (cstate == IDLE)    && rd_req_r;// 空闲状态下，读请求
assign WR_REQ_WR_WAIT = (cstate == WR_REQ)  && 1;		// 写请求发送后，等待
assign RD_REQ_RD_WAIT = (cstate == RD_REQ)  && 1;		// 读请求发送后，等待
assign WR_WAIT_WR_REQ = (cstate == WR_WAIT) && done;	// 写完一个Byte后，没写完要继续写数据
assign WR_WAIT_DONE   = (cstate == WR_WAIT) && end_cnt_byte;// 数据写完了
assign RD_WAIT_RD_REQ = (cstate == RD_WAIT) && done;		// 读完一个Byte后，要继续读
assign RD_WAIT_DONE   = (cstate == RD_WAIT) && end_cnt_byte;// 数据读完了
assign DONE_IDLE      = (cstate == DONE)    && 1;			// 读写完成后，回到空闲状态

//根据设备ID，读写地址，读写数据，生成IIC指令
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		device_id_w <= 8'b0;
		device_id_r <= 8'b0;
		end
	else begin
		device_id_r <= {device_id,1'b1};// 设备的ID，写指令寄存器
		device_id_w <= {device_id,1'b0};// 设备的ID，读指令寄存器
	end
end

// 读写申请寄存，消抖以及不用持续申请
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		wr_req_r <=0;
		rd_req_r <= 0;
	end else begin
		wr_req_r <= wr_req;
		rd_req_r <= rd_req;
	end
end

// 地址有效
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		addr_r <= 'd0;
	end else if (reg_addr_vld) begin
		addr_r <= reg_addr;
	end
end

// 发送过的byte数计数
always @(posedge clk or negedge rst_n)begin 
	if(!rst_n)begin
		cnt_byte <= 'd0;
		end 
	else if(add_cnt_byte)begin 
		if(end_cnt_byte)begin 
			cnt_byte <= 'd0;
		end	else begin 
			cnt_byte <= cnt_byte + 1'd1;
		end 
	end
end 

// 读写byte数计数
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin 
		num <= 1;
	end else if (wr_req) begin
		num <= 3;
	end else if (rd_req) begin
		num <= 5;
	end else if (end_cnt_byte) begin
		num <= 1;
	end
end

// 状态机
always @(posedge clk or negedge rst_n) begin 
	if(!rst_n)begin
		cstate <= IDLE;
	end else begin 
		cstate <= nstate;
	end 
end
    
// 状态机转换
always @(*) begin
	case(cstate)
		IDLE    :begin
			if (IDLE_WR_REQ) begin
				nstate = WR_REQ;
			end	else if (IDLE_RD_REQ) begin
				nstate = RD_REQ;
			end	else begin
				nstate = cstate;
			end
		end 
		WR_REQ  :begin
			if (WR_REQ_WR_WAIT) begin
				nstate = WR_WAIT;
			end	else begin
				nstate = cstate;
			end
		end 
		WR_WAIT :begin
			if (WR_WAIT_DONE) begin
				nstate = DONE;
			end	else if (WR_WAIT_WR_REQ) begin
				nstate = WR_REQ;
			end	else begin
				nstate = cstate;
			end
		end 
		RD_REQ  :begin
			if (RD_REQ_RD_WAIT) begin
				nstate = RD_WAIT;
			end	else begin
				nstate = cstate;
			end
		end 
		RD_WAIT :begin
			if (RD_WAIT_DONE) begin
				nstate = DONE;
			end	else if (RD_WAIT_RD_REQ) begin
				nstate = RD_REQ;
			end	else begin
				nstate = cstate;
			end
		end 
		DONE    :begin
			if (DONE_IDLE) begin
				nstate = IDLE;
			end	else begin
				nstate = cstate;
			end
		end 
		default : nstate = cstate;
	endcase
end

// 根据cnt_byte和cstate，控制要发送的内容和指令
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cmd_vld <= 'b0;
		cmd <= 5'd0;
		op_wr_data <= 8'd0;
		adc_mdata_r <= 8'd0;
		adc_ldata_r <= 8'd0;
	end	else begin
		case (cstate)
			RD_REQ:begin
				case (cnt_byte)
					0: 	begin
						cmd_vld <= 1;
						cmd <= `START_BIT | `WRITE_BIT;
						op_wr_data <= device_id_w;
						adc_mdata_r <= adc_mdata_r;
						adc_ldata_r <= adc_ldata_r;
					end  
					1:	begin 
						cmd_vld <= 1;
						cmd <= `WRITE_BIT;
						op_wr_data <= addr_r[7:0];
						adc_mdata_r <= adc_mdata_r;
						adc_ldata_r <= adc_ldata_r;
					end
						2:  begin 
						cmd_vld <= 1;
						cmd <= (`START_BIT | `WRITE_BIT);
						op_wr_data <= device_id_r;
						adc_mdata_r <= adc_mdata_r;
						adc_ldata_r <= adc_ldata_r;
					end
					3:  begin
						cmd_vld <= 1;
						cmd <= `READ_BIT;
						op_wr_data <= 8'd0;
						adc_mdata_r <= op_rd_data;
						adc_ldata_r <= adc_ldata_r;
					end
					4:  begin 
						cmd_vld <= 1;
						cmd <= `READ_BIT | `STOP_BIT;
						op_wr_data <= 8'd0;
						adc_mdata_r <= adc_mdata_r;
						adc_ldata_r <= op_rd_data;
					end
					default: begin
						cmd_vld <= 0;
						cmd <= 5'd0;
						op_wr_data <= 8'd0;
						adc_mdata_r <= adc_mdata_r;
						adc_ldata_r <= adc_ldata_r;
					end
				endcase
			end
			WR_REQ:begin
				case (cnt_byte)
					0:  begin
						cmd_vld <= 1;
						cmd <= (`START_BIT | `WRITE_BIT);
						op_wr_data <= device_id_w;		
						adc_mdata_r <= adc_mdata_r;
						adc_ldata_r <= adc_ldata_r;
					end
					1:  begin 
						cmd_vld <= 1;
						cmd <= `WRITE_BIT;			
						op_wr_data <=  op_wr_data;		
						adc_mdata_r <= adc_mdata_r;
						adc_ldata_r <= adc_ldata_r;
					end
					2:  begin 
						cmd_vld <= 1;
						cmd <= `WRITE_BIT | `STOP_BIT;
						op_wr_data <=  op_wr_data;		
						adc_mdata_r <= adc_mdata_r;
						adc_ldata_r <= adc_ldata_r;
					end 
					default: begin
						cmd_vld <= 0;
						cmd <= 5'd0;
						op_wr_data <= 8'd0;
						op_wr_data <=  op_wr_data;		
						adc_mdata_r <= adc_mdata_r;
						adc_ldata_r <= adc_ldata_r;
					end
				endcase
			end
			default:begin
				cmd_vld <= 0;
				cmd <= 5'd0;
				op_wr_data <= 8'd0;
				adc_mdata_r <= adc_mdata_r;
				adc_ldata_r <= adc_ldata_r;
			end
		endcase
	end
end

assign rd_data_adc[7:0] = {adc_ldata_r[3:0],adc_mdata_r[7:4]};// 取读到的数据，取全部范围

endmodule