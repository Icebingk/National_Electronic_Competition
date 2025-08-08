module ADF4351(
    input     wire  sys_clk,
    input     wire  rst_n,
    
    output     reg   ce,
    output     reg   le,
    output     reg   sclk,
    output     reg   sdata
);

parameter reg_r0  =32'h00580005;
parameter reg_r1  =32'h0060a43c;  // 32分频+主输出使能
parameter reg_r2  =32'h006004b3;  
parameter reg_r3  =32'h0D003Fc2 | (25 << 14);  // R=1, 电荷泵5mA 
parameter reg_r4  =32'h08008011;  // MOD=100, Phase=1
parameter reg_r5  =32'h00000000 | (35 << 15);  // INT=112, FRAC=64
 
parameter IDLE    = 2'b00;
parameter WAIT    = 2'b01;
parameter WRITE   = 2'b11;
parameter INIT    = 2'b10;  // 新增初始化状态
 
reg  [5:0]  cnt_bity        ;    //时钟脉冲计数器 计数到32
reg  [3:0]  cnt_bit         ;    //寄存器计数器，计数到6
reg  [31:0] data            ;  
reg  [1:0]  state           ;
reg  [2:0]  cnt_clk         ;
reg         power_on_init   ;    //上电初始化标志
reg  [15:0] init_delay_cnt  ;    //上电延时计数器

// 上电初始化标志和延时计数器
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n) begin
        power_on_init <= 1'b0;
        init_delay_cnt <= 16'd0;
    end
    else if(init_delay_cnt < 16'd10000) begin  // 延时足够长确保系统稳定
        init_delay_cnt <= init_delay_cnt + 1'b1;
        power_on_init <= 1'b0;
    end
    else if(state == IDLE && !power_on_init) begin
        power_on_init <= 1'b1;  // 设置初始化标志
    end
    else if(state == IDLE && (cnt_bit == 4'd5) && (cnt_bity == 6'd32) && (!sclk)) begin
        power_on_init <= 1'b1;  // 完成一轮初始化
    end
end

//cnt_clk
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)
        cnt_clk <= 3'd0;
    else if(state == WAIT)
        cnt_clk <= cnt_clk + 3'd1;
    else
        cnt_clk <= 3'd0;
end
 
//状态转移
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)
        state <= IDLE;
    else case(state)
        IDLE:  if(init_delay_cnt >= 16'd10000 && !power_on_init)
                    state <= WRITE;
               else
                    state <= state;
        WRITE:  if((cnt_bit == 4'd5) && (cnt_bity == 6'd32) && (!sclk))
                    state <= IDLE;
                else if((cnt_bit < 4'd5) && (cnt_bity == 6'd32) && (!sclk))
                    state <= WAIT;
                else
                    state <= state;
        WAIT:   if(cnt_clk == 3'd3)
                    state <= WRITE;
                else
                    state <= state;
        default:    state <= IDLE;
    endcase
end
 
//ce
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)
        ce <= 1'd0;
    else if(data == 32'd0)
        ce <= 1'd0;
    else if(data == reg_r0||data == reg_r1||data == reg_r2||data == reg_r3||data == reg_r4||data == reg_r5)
        ce <= 1'd1;
end
 
//cnt_bit  计数到5
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)
        cnt_bit <= 4'd0;
    else if((cnt_bity == 6'd32)&&(cnt_bit == 4'd5)&&(!sclk))
        cnt_bit <= 4'd0;
    else if((cnt_bity == 6'd32)&&(cnt_bit <4'd5)&&(!sclk))
        cnt_bit <= cnt_bit+1'd1;
    else
        cnt_bit <= cnt_bit;
end
 
//cnt_bity 计数到32
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)
        cnt_bity <= 6'd0;
    else if((!sclk)&&(cnt_bity == 6'd32))
        cnt_bity <= 6'd0;
    else if((cnt_clk==3'd3)||(!sclk && state == WRITE))
        cnt_bity <= cnt_bity + 6'd1;
    else
        cnt_bity <= cnt_bity;
end
 
//data
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)
        data <= 32'd0;
    else case(cnt_bit)
        4'd0 :   data <= reg_r5;
        4'd1 :   data <= reg_r4;
        4'd2 :   data <= reg_r3;
        4'd3 :   data <= reg_r2;
        4'd4 :   data <= reg_r1;
        4'd5 :   data <= reg_r0;
        default: data <= 32'd0;
    endcase
end
 
//sclk
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)
        sclk <= 1'd1;
    else if((!sclk)&&(cnt_bity == 6'd32))
        sclk <= 1'd1;
    else if(state==WRITE)
        sclk <= ~sclk;
    else
        sclk <= sclk;
end
 
//le拉低时数据进行传输
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)
        le <= 1'd1;
    else if(init_delay_cnt >= 16'd10000 && !power_on_init && state == IDLE)
        le <= 1'd0;
    else if((!sclk)&&(cnt_bity == 6'd32))
        le <= 1'd1;
    else if((state == WAIT)&&(cnt_clk >= 3'd2))
        le <= 1'd0;
    else
        le <= le;
end
 
//sdata
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)
        sdata <= 1'd0;
    else if((!sclk)&&(cnt_bity == 6'd32))
        sdata <= 1'd0;
    else if((sclk && cnt_bity<6'd32 && state == WRITE)||(cnt_clk== 3'd3))
        sdata <= data[(31-cnt_bity)];
    else
        sdata <= sdata;
end
 
endmodule