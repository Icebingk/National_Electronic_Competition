module eeprom ( 
	input	wire					clk		    			,
	input	wire			        rst_n   				,
	input   wire                   	wr_req      			,
	input   wire                    rd_req      			,
	input   wire   [6:0]            device_id   			,
	input   wire   [7:0]  			reg_addr    			,
	input   wire                    reg_addr_vld			,
	input   wire   [7:0]    		wr_data     			,
	input   wire                    wr_data_vld 			,
    input   wire   [4:0]            wr_bytes    			, // 新增端口：指定要写入的字节数
	output  wire   [7:0]            rd_data     			,
	output  wire                    rd_data_vld 			,
	input   wire   [4:0]            rd_bytes    			, // 新增端口：指定要读取的字节数
	output  wire                    ready       			,

	output  wire   [7:0]            op_wr_data_eeprom		,
	output  wire   [4:0]            cmd_eeprom  			,
	output  wire                    cmd_vld_eeprom			,
	input   wire   [7:0]            op_rd_data_eeprom		,
	input   wire                    op_rd_data_vld_eeprom	,
	input   wire                    rev_ack_eeprom			,
	input   wire                    done_eeprom  		      // 读写完成信号
);								 

//para define
`define     	START_BIT   5'b00001
`define     	WRITE_BIT   5'b00010
`define     	READ_BIT    5'b00100
`define     	STOP_BIT    5'b01000
`define     	ACK_BIT     5'b10000
localparam  	IDLE     = 6'b000001,
				WR_REQ   = 6'b000010,
				WR_WAIT  = 6'b000100,
				RD_REQ   = 6'b001000,
				RD_WAIT  = 6'b010000,
				DONE     = 6'b100000;
localparam MAX_RD_BYTES = 8;  // 最大连续读取字节数
localparam MAX_WR_BYTES = 8;  // 最大连续写入字节数
				
// localparam 	WR_CTRL_BYTE = 8'b1010_0000;
// localparam  	RD_CTRL_BYTE = 8'b1010_0001;

//wire define
wire    IDLE_WR_REQ     ;
wire    IDLE_RD_REQ     ;
wire    WR_REQ_WR_WAIT  ;
wire    RD_REQ_RD_WAIT  ;
wire    WR_WAIT_WR_REQ  ;
wire    WR_WAIT_DONE    ;
wire    RD_WAIT_RD_REQ  ;
wire    RD_WAIT_DONE    ;
wire    DONE_IDLE       ;
wire	done            ;
wire	add_cnt_byte	;
wire	end_cnt_byte	;

//reg define
reg	[7:0] 	device_id_r  	;// 设备ID+读写位
reg [7:0] 	device_id_w  	;// 设备ID+读写位
reg	[5:0]	cstate     		;
reg	[5:0]	nstate     		;
reg	[4:0]	num             ;
reg	[4:0]	cmd             ;
reg			cmd_vld         ;
reg	[7:0]	op_wr_data      ;
reg	[15:0]	addr_r          ;
reg	[4:0]	cnt_byte	   	;
reg			wr_req_r		;
reg			rd_req_r		;

reg [7:0] wr_data_buffer [MAX_WR_BYTES-1:0];  // 数据缓冲区
reg [4:0] wr_data_cnt;  // 已缓存的数据数量
reg [7:0] rd_data_buffer [MAX_RD_BYTES-1:0];  // 读取数据缓冲区
reg [4:0] rd_data_cnt;  // 已读取的数据数量

assign add_cnt_byte = done;
assign end_cnt_byte = add_cnt_byte && cnt_byte == num - 1;
assign IDLE_WR_REQ    = (cstate == IDLE)    && wr_req_r;
assign IDLE_RD_REQ    = (cstate == IDLE)    && rd_req_r;
assign WR_REQ_WR_WAIT = (cstate == WR_REQ)  && 1;
assign RD_REQ_RD_WAIT = (cstate == RD_REQ)  && 1;
assign WR_WAIT_WR_REQ = (cstate == WR_WAIT) && done;
assign WR_WAIT_DONE   = (cstate == WR_WAIT) && end_cnt_byte;
assign RD_WAIT_RD_REQ = (cstate == RD_WAIT) && done;
assign RD_WAIT_DONE   = (cstate == RD_WAIT) && end_cnt_byte;
assign DONE_IDLE      = (cstate == DONE)    && 1;
assign ready = cstate == IDLE;         

//端口连线
////output
assign op_wr_data_eeprom = op_wr_data;// 发送数据
assign cmd_eeprom = cmd;// 指令寄存器
assign cmd_vld_eeprom = cmd_vld;// 指令有效信号
////input
assign done = done_eeprom;// 读写完成信号
assign rd_data = op_rd_data_eeprom;// 读数据
assign rd_data_vld = op_rd_data_vld_eeprom;// 读数据有效信号

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

//
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		wr_req_r <=0;
		rd_req_r <= 0;
		end
	else begin
		wr_req_r <= wr_req;
		rd_req_r <= rd_req;
	end
end
    
//
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		addr_r <= 'd0;
		end
	else if (reg_addr_vld) begin
		addr_r <= reg_addr;
	end
end

genvar i;
generate
	for (i = 0; i < MAX_WR_BYTES; i = i + 1) begin : wr_data_buffer_gen
		always @(posedge clk or negedge rst_n) begin
			if (!rst_n) begin
				wr_data_buffer[i] <= 8'h00;
			end else if (wr_data_vld && wr_data_cnt == i && wr_data_cnt < MAX_WR_BYTES) begin
				wr_data_buffer[i] <= wr_data;
			end
		end
	end
endgenerate

genvar j;
generate
	for (j = 0; j < MAX_RD_BYTES; j = j + 1) begin : rd_data_buffer_gen
		always @(posedge clk or negedge rst_n) begin
			if (!rst_n) begin
				rd_data_buffer[j] <= 8'h00;
			end else if (rd_data_vld && rd_data_cnt == j && rd_data_cnt < MAX_RD_BYTES) begin
				rd_data_buffer[j] <= rd_data;
			end 
		end
	end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_data_cnt <= 'd0;
    end else if (wr_data_vld && wr_data_cnt < MAX_WR_BYTES) begin
		wr_data_cnt <= wr_data_cnt + 1'd1;
	end else if (cstate == DONE) begin
        wr_data_cnt <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_data_cnt <= 'd0;
    end else if (rd_data_vld && rd_data_cnt < MAX_RD_BYTES) begin
        rd_data_cnt <= rd_data_cnt + 1'd1;
    end else if (cstate == DONE) begin
        rd_data_cnt <= 'd0;
    end
end

//
always @(posedge clk or negedge rst_n)begin 
	if(!rst_n)begin
		cnt_byte <= 'd0;
		end 
	else if(add_cnt_byte)begin 
		if(end_cnt_byte)begin 
			cnt_byte <= 'd0;
			end
		else begin 
			cnt_byte <= cnt_byte + 1'd1;
			end 
	end
end 
    
    
//
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		num <= 1;
	end else if (wr_req) begin
		num <= 3 + wr_bytes; // 3 bytes for control + address + data
	end	else if (rd_req) begin
		num <= 4 + rd_bytes; // 4 bytes for control + address + data
	end else if (end_cnt_byte) begin
		num <= 1;
	end
end
  
//
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
		IDLE    :begin
			if (IDLE_WR_REQ) begin
				nstate = WR_REQ;
				end
			else if (IDLE_RD_REQ) begin
				nstate = RD_REQ;
				end
			else begin
				nstate = cstate;
				end
			end 
		WR_REQ  :begin
			if (WR_REQ_WR_WAIT) begin
				nstate = WR_WAIT;
				end
			else begin
				nstate = cstate;
				end
			end 
		WR_WAIT :begin
			if (WR_WAIT_DONE) begin
				nstate = DONE;
				end
			else if (WR_WAIT_WR_REQ) begin
				nstate = WR_REQ;
				end
			else begin
				nstate = cstate;
				end
			end 
		RD_REQ  :begin
			if (RD_REQ_RD_WAIT) begin
				nstate = RD_WAIT;
				end
			else begin
				nstate = cstate;
				end
			end 
		RD_WAIT :begin
			if (RD_WAIT_DONE) begin
				nstate = DONE;
				end
			else if (RD_WAIT_RD_REQ) begin
				nstate = RD_REQ;
				end
			else begin
				nstate = cstate;
				end
			end 
		DONE    :begin
			if (DONE_IDLE) begin
				nstate = IDLE;
				end
			else begin
				nstate = cstate;
				end
			end 
		default : nstate = cstate;
	endcase
end

//                
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cmd_vld <= 0;
		cmd <= 5'h0;
		op_wr_data <= 8'h00;
	end	else begin
        case (cstate)
            RD_REQ:begin
                case (cnt_byte)
                    0:begin 
						cmd_vld <= 1;
						cmd <= (`START_BIT | `WRITE_BIT);
						op_wr_data <= device_id_w;
                    end
                    1:begin 
						cmd_vld <= 1;
						cmd <= (`WRITE_BIT);
						op_wr_data <= addr_r[15:8];
                    end
                    2:begin 
						cmd_vld <= 1;
						cmd <= (`WRITE_BIT);
						op_wr_data <= addr_r[7:0];
					end
                    3:begin 
						cmd_vld <= 1;
						cmd <= (`START_BIT | `WRITE_BIT);
						op_wr_data <= device_id_r;
					end
                    default: begin 
						if (cnt_byte >= 4 && cnt_byte < (4 + rd_bytes)) begin
							cmd_vld <= 1;
							// 最后一个字节添加停止位
							if (cnt_byte == (4 + rd_bytes - 1))
								cmd <= (`READ_BIT | `STOP_BIT | `ACK_BIT);
							else
								cmd <= (`READ_BIT);
							op_wr_data <= 8'h00;
						end
						else begin
							cmd_vld <= 0;
							cmd <= cmd;
							op_wr_data <= op_wr_data;
						end
					end
                endcase
                end
            WR_REQ:begin
                case (cnt_byte)
                    0:begin 
						cmd_vld <= 1;
						cmd <= (`START_BIT | `WRITE_BIT);
						op_wr_data <= device_id_w;
					end
                    1:begin 
						cmd_vld <= 1;
						cmd <= (`WRITE_BIT);
						op_wr_data <= addr_r[15:8];
					end
                    2:begin 
						cmd_vld <= 1;
						cmd <= (`WRITE_BIT);
						op_wr_data <= addr_r[7:0];
					end
                    default: begin 
                            if (cnt_byte >= 3 && cnt_byte < (3 + wr_bytes)) begin
                                cmd_vld <= 1;
                                // 最后一个字节添加停止位
                                if (cnt_byte == (3 + wr_bytes - 1))
                                    cmd <= (`WRITE_BIT | `STOP_BIT);
                                else
                                    cmd <= (`WRITE_BIT);
                                op_wr_data <= wr_data_buffer[cnt_byte - 3];
                            end
                            else begin
                                cmd_vld <= 0;
                                cmd <= cmd;
                                op_wr_data <= op_wr_data;
                            end
                    end
                endcase
            end
            default: begin 
                    cmd_vld <= 0;
                    cmd <= cmd;
                    op_wr_data <= op_wr_data;
            end
        endcase	end
end

endmodule
