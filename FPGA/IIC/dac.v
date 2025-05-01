module dac(
	input							clk		   			,// 系统时钟
	input				            rst_n	   			,// 系统复位
	input                       	wr_req      		,// 写请求
	input                        	rd_req      		,// 读请求
	input       [6:0]             	device_id   		,// 设备ID
	input       [7:0]  				reg_addr    		,// 寄存器地址
	input                         	reg_addr_vld		,// 寄存器地址有效
	input       [7:0]             	wr_data     		,// 写入数据
	input                         	wr_data_vld 		,// 写入数据有效
	output reg  [7:0]             	rd_data     		,// 读出数据
	output                        	rd_data_vld 		,// 数据有效
	output                        	ready       		,// 空闲

	output wire [4:0]               cmd_dac				,// 指令寄存器
	output wire                     cmd_vld_dac			,// 指令有效信号
	output wire [7:0]               op_wr_data_dac		,// 发送数据
	input  wire [7:0]               op_rd_data_dac		,// 读数据
	input  wire                     op_rd_data_vld_dac	,// 读数据有效信号
	input  wire                     rev_ack_dac			,// 应答信号
	input  wire                     done_dac    		 // 读写完成信号
);

//para define
`define     	START_BIT   5'b00001// 起始位指令
`define     	WRITE_BIT   5'b00010// 写数据指令
`define     	READ_BIT    5'b00100// 读数据指令
`define     	STOP_BIT    5'b01000// 停止位指令
`define     	ACK_BIT     5'b10000// 应答位指令
localparam  	IDLE     = 6'b000001,
				WR_REQ   = 6'b000010,
				WR_WAIT  = 6'b000100,
				RD_REQ   = 6'b001000,
				RD_WAIT  = 6'b010000,
				DONE     = 6'b100000;				
// localparam  	WR_CTRL_BYTE = 8'b1001_1000;// 写控制字节
// localparam  	RD_CTRL_BYTE = 8'b1001_1001;// 读控制字节

//reg define
reg [7:0] 	device_id_r		;// 设备ID+1，读出
reg [7:0] 	device_id_w 	;// 设备ID+0，写入
reg [5:0]	cstate     		;// 当前状态
reg	[5:0]	nstate     		;// 下一个状态
reg	[4:0]	cmd				;// 命令
reg			cmd_vld			;// 命令有效
reg	[7:0]	op_wr_data  	;// 写入数据
reg	[15:0]	addr_r   		;// 访问地址
reg			wr_req_r		;// 写请求
reg			rd_req_r		;// 读请求
reg [7:0] 	dac_mdata_r		;// DAC高8位
reg [7:0] 	dac_ldata_r		;// DAC低8位
reg	[2:0]	cnt_byte		;// 对IIC发送信息的字节计数
reg	[2:0]	num 			;// 字节计数，读写完成一次通信需要发送信息给IIC的次数

//状态控制线
wire    	IDLE_WR_REQ     ;
wire    	IDLE_RD_REQ     ;
wire    	WR_REQ_WR_WAIT  ;
wire    	RD_REQ_RD_WAIT  ;
wire    	WR_WAIT_WR_REQ  ;
wire    	WR_WAIT_DONE    ;
wire    	RD_WAIT_RD_REQ  ;
wire    	RD_WAIT_DONE    ;
wire    	DONE_IDLE       ;

wire		done			;// IIC通信完成，空闲信号
wire		add_cnt_byte	;// 字节计数加1允许信号线
wire		end_cnt_byte	;// 字节计数结束
wire [7:0]	op_rd_data  	;// 读出数据
wire [7:0] 	dac_mdata = wr_data_vld?{4'b0000,wr_data[7:4]}:dac_mdata;	// 高四位为控制位，这里的指令为0000，低四位为数据位的高四位
wire [7:0] 	dac_ldata = wr_data_vld?{wr_data[3:0],4'b0000}:dac_ldata;	// 高四位为数据位的低四位，低四位为无效位置

//端口连线
////output
assign op_wr_data_dac = op_wr_data;// 发送数据
assign cmd_dac = cmd;// 指令寄存器
assign cmd_vld_dac = cmd_vld;// 指令有效信号
////input
assign done = done_dac;// 读写完成信号
assign op_rd_data = op_rd_data_dac;// 读数据
assign rd_data_vld = op_rd_data_vld_dac;// 读数据有效信号


// 计数已经发送字节
assign add_cnt_byte = done; 
assign end_cnt_byte = add_cnt_byte && cnt_byte == num - 1;
assign IDLE_WR_REQ    = (cstate == IDLE)    && wr_req_r;// 空闲状态，写请求
assign IDLE_RD_REQ    = (cstate == IDLE)    && rd_req_r;// 空闲状态，读请求
assign WR_REQ_WR_WAIT = (cstate == WR_REQ)  && 1;		// 写请求状态，等待
assign RD_REQ_RD_WAIT = (cstate == RD_REQ)  && 1;		// 读请求状态，等待
assign WR_WAIT_WR_REQ = (cstate == WR_WAIT) && done;	// 写完一个byte，重新写
assign WR_WAIT_DONE   = (cstate == WR_WAIT) && end_cnt_byte;// 所有byte写完，可结束
assign RD_WAIT_RD_REQ = (cstate == RD_WAIT) && done;		// 读完一个byte，重新读
assign RD_WAIT_DONE   = (cstate == RD_WAIT) && end_cnt_byte;// 所有byte读完，可结束
assign DONE_IDLE      = (cstate == DONE)    && 1;			// 完成状态，空闲
assign ready = cstate == IDLE;         


//设置设备ID+读写标志位
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		device_id_w <= 8'b0;
		device_id_r <= 8'b0;
		end
	else begin
		device_id_r <= {device_id,1'b1};
		device_id_w <= {device_id,1'b0};
	end
end

//读写申请
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		wr_req_r <=0;
		rd_req_r <= 0;
	end	else begin
		wr_req_r <= wr_req;
		rd_req_r <= rd_req;
	end
end

//地址触发器
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		addr_r <= 'd0;
	end	else if (reg_addr_vld) begin
		addr_r <= reg_addr;
	end
end

//写请求，将数据缓存一下
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		dac_mdata_r <= 'd0;
		dac_ldata_r <= 'd0;
	end	else if (wr_req) begin
		dac_mdata_r <= dac_mdata;
		dac_ldata_r <= dac_ldata;
	end
end

//计数控制
always @(posedge clk or negedge rst_n) begin 
	if(!rst_n) begin
		cnt_byte <= 'd0;
	end	else if(add_cnt_byte) begin// 计数字节
		if(end_cnt_byte)begin 
			cnt_byte <= 'd0;
		end	else begin 
			cnt_byte <= cnt_byte + 1'd1;
		end
	end
end

//不同状态下，需要发送的不同字节
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		num <= 1;
	end	else if (wr_req) begin
		num <= 3;
	end	else if (rd_req) begin
		num <= 6;
	end	else if (end_cnt_byte) begin
		num <= 1;
	end
end

// 状态机
always @(posedge clk or negedge rst_n)begin 
	if(!rst_n)begin
		cstate <= IDLE;
	end else begin 
		cstate <= nstate;
	end 
end

//状态机
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

/*
* 转换流程：（写数据流程）
* 		1. 第一个字节：设备地址+写控制位
* 		2. 第二个字节：控制+高4位数据
* 		3. 第三个字节：低4位数据+4为无效位
* 读数据流程：
* 		1. 第一个字节：设备地址+写控制位
* 		2. 第二个字节：寄存器地址
* 		3. 第三个字节：寄存器地址
* 		4. 第四个字节：设备地址+读控制位
* 		5. 第五个字节：读数据
* 		6. 第六个字节：读数据
* 
*/
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cmd_vld     	<=	'b0;
		cmd         	<=	4'h0;
		op_wr_data  	<=	8'h00;
		rd_data  		<=	8'h00;// op_rd_data
	end	else begin
		case (cstate)
			RD_REQ:begin
				case (cnt_byte)
					0:begin
						cmd_vld     	<=	'b1;
						cmd         	<=	`START_BIT | `WRITE_BIT;
						op_wr_data  	<=	device_id_w;
						rd_data  		<=	op_rd_data;
					end
					1:begin
						cmd_vld     	<=	'b1;
						cmd         	<=	`WRITE_BIT;
						op_wr_data  	<=	addr_r[15:8];
						rd_data  		<=	op_rd_data;
					end
					2:begin
						cmd_vld     	<=	'b1;
						cmd         	<=	`WRITE_BIT;
						op_wr_data  	<=	addr_r[7:0];
						rd_data  		<=	op_rd_data;					
					end
					3:begin
						cmd_vld     	<=	'b1;
						cmd         	<=	`START_BIT | `WRITE_BIT;
						op_wr_data  	<=	device_id_r;
						rd_data  		<=	op_rd_data;					
					end
					4:begin
						cmd_vld     	<=	'b1;
						cmd         	<=	`READ_BIT | `STOP_BIT;
						op_wr_data  	<=	8'h00;
						rd_data  		<=	op_rd_data;					
					end
					5:begin
						cmd_vld     	<=	'b1;
						cmd         	<=	`READ_BIT | `STOP_BIT;
						op_wr_data  	<=	8'h00;
						rd_data  		<=	op_rd_data;					
					end
					default: begin 
						cmd_vld     	<=	'b0;
						cmd         	<=	4'h0;
						op_wr_data  	<=	8'h00;
						rd_data  		<=	rd_data;// op_rd_data
					end
				endcase
				end
			WR_REQ:begin
				case (cnt_byte)
					0:begin
						cmd_vld     	<=	'b1;
						cmd         	<=	`START_BIT | `WRITE_BIT;
						op_wr_data  	<=	device_id_w;
						rd_data  		<=	rd_data;
					end
					1:begin
						cmd_vld     	<=	'b1;
						cmd         	<=	`WRITE_BIT;
						op_wr_data  	<=	dac_mdata;
						rd_data  		<=	rd_data;
					end
					2:begin
						cmd_vld     	<=	'b1;
						cmd         	<=	`WRITE_BIT | `STOP_BIT;
						op_wr_data  	<=	dac_ldata;
						rd_data  		<=	rd_data;
					end
					default:begin
						cmd_vld     	<=	'b0;
						cmd         	<=	4'h0;
						op_wr_data  	<=	8'h00;
						rd_data  		<=	rd_data;
					end
				endcase
				end
			default:begin
				cmd_vld     	<=	'b0;
				cmd         	<=	4'h0;
				op_wr_data  	<=	8'h00;
				rd_data  		<=	rd_data;
			end
		endcase
	end
end

endmodule



