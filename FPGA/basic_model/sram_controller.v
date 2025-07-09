module sram_controller(
	input	wire 					clk				,	//时钟
	input 	wire					rst_n			,	//复位信号
	
	// 低电平有效
	output	wire					we				,	//写使能	
	output 	wire					oe				,	//读使能
	output 	wire					ce				,	//片选信号
	inout	wire	[7:0]			data			, 	//数据
	output  wire    [16:0]          addr_out		,	//地址	

	input 							wr_request		,	//写请求
	input	wire	 				rd_request		,	//读请求
	input  	wire	[16:0]			addr_in			,	//地址
	input	wire	[7:0] 			wr_data			,	//写数据
	output	reg		[7:0] 			rd_data 			//读数据
);

//para define
`define    	DELAY_80NS	(cnt==3'd7)

parameter   IDLE    = 4'd0,
            WRT0    = 4'd1,
            WRT1    = 4'd2,
            REA0    = 4'd3,
            REA1    = 4'd4;

//reg define
reg	[2:0] 	cnt				;   
reg	[3:0] 	cstate,nstate	;
reg 		sdlink			;           

// 计数器，用于延时，因为SRAM的读写需要一定的时间
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) 
		cnt <= 3'd0;
    else if(cstate == IDLE) 	
		cnt <= 3'd0;
    else 
		cnt <= cnt+1'b1;
end

//状态机的状态转移
always @ (posedge clk or negedge rst_n)
    if(!rst_n) 
		cstate <= IDLE;
    else
		cstate <= nstate;

//Fsm
always @ (*)
    case (cstate)
        IDLE: //单工的
			if(wr_request)// 如果有写请求，进入WRT0状态
				nstate = WRT0;
			else if(rd_request)// 如果有读请求，进入REA0状态
				nstate = REA0;
			else 
				nstate = IDLE;
        WRT0:// 写数据状态，要延时80ns
			if(`DELAY_80NS) 
				nstate = WRT1;
			else
				nstate = WRT0;    
        WRT1: 		
			nstate = IDLE;
        REA0: 
			if(`DELAY_80NS) 
				nstate = REA1;
            else 
				nstate = REA0;
        REA1: 		
			nstate = IDLE;
		default: 	
			nstate = IDLE;
     endcase           


//在REA1状态下，将数据传递给rd_data
always @ (posedge clk or negedge rst_n)
   	if(!rst_n) 
		rd_data <= 8'd0;
   	else if(cstate == REA1) begin 
		rd_data <= data; 
	end

//SRAM的读写控制
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) 
		sdlink <=1'b0;
    else begin
        case (cstate)
            IDLE: 
				if(wr_request) 
					sdlink <= 1'b1;
				else if(rd_request) 
					sdlink <= 1'b0;
				else 
					sdlink <= 1'b0;
            WRT0: 
				sdlink <= 1'b1;
            default: 
				sdlink <= 1'b0;
        endcase
	end
end

// 读写信号位分配，片选位分配，数据位分配
assign data = sdlink ? wr_data : 8'hz			;   
assign addr_out = (cstate != IDLE)?addr_in:17'b0;
assign we 	= ~sdlink							;
assign oe 	= sdlink							;
assign ce 	=  (cstate != IDLE)? 1'b0 : 1'b1;

endmodule