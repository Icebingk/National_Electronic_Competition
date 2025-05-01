module IIC_Top(
  input     wire                    sys_clk,          // 系统时钟
  input     wire                    rst_n,            // 系统复位

  input     wire  [3:0]             control,          // 要控制的设备，其中eeprom会带有rw标志位
  input     wire                    device_vld,       // 设备有效信号线  
  input     wire  [7:0]             in_wr_data,       // 要写入的数据，可以是控制dac的数据，也可以是要写入eeprom的数据
  input     wire                    in_wr_data_vld,   // 写入数据有效信号线
  output    wire  [7:0]             out_rd_data,      // 读取到的数据
  output    wire                    out_rd_data_vld,  // 读出数据有效信号线

  output    wire                    scl,              // IIC时钟线
  inout     wire                    sda               // IIC数据线
);
// 设备名称常量定义 (ASCII)
localparam [3:0] ADC      = 4'b0001; // ADC
localparam [3:0] DAC      = 4'b0010; // DAC
localparam [3:0] EEPROM_R = 4'b1100; // 读EEPROM
localparam [3:0] EEPROM_W = 4'b0100; // 写EEPROM
// 设备控制信号线定义
localparam  device_id_adc     = 7'b101_0100;
localparam  device_id_dac     = 7'b100_1100;
localparam  device_id_eeprom  = 7'b101_0000;

//////////////////////////////   ADC  //////////////////////////////////////////////////
//ADC和顶层的控制信号定义
wire        wr_req_adc            ;
reg         rd_req_adc            ;
wire [7:0]  reg_addr_adc          ;
reg         reg_addr_vld_adc      ;
wire [7:0]  wr_data_adc           ;
wire        wr_data_vld_adc       ;
wire [7:0]  rd_data_adc           ;
reg  [7:0]  rd_data_adc_r       ;
wire        rd_data_vld_adc       ;
reg         ready_adc             ;
//ADC和IIC的控制信号定义  
wire [7:0]  op_wr_data_adc        ;
wire [4:0]  cmd_adc               ;
wire        cmd_vld_adc           ;
reg  [7:0]  op_rd_data_adc        ;
reg         op_rd_data_vld_adc    ;
reg         rev_ack_adc           ;
reg         done_adc              ;
//固定数据端口
assign wr_req_adc = 1'b0; // ADC写请求
assign reg_addr_adc = 8'h00; // 读ADC数据寄存器地址
assign reg_addr_vld_adc = 1'b1; // 寄存器地址有效信号线
assign wr_data_adc = 8'h00; // 写ADC空
assign wr_data_vld_adc = 1'b0; // 写ADC数据有效信号线

//////////////////////////////   DAC  //////////////////////////////////////////////////
//DAC和顶层的控制信号定义
reg         wr_req_dac            ;
wire        rd_req_dac            ;
wire [7:0]  reg_addr_dac          ;
wire        reg_addr_vld_dac      ;
reg  [7:0]  wr_data_dac           ;
reg         wr_data_vld_dac       ;
wire [7:0]  rd_data_dac           ;// 空闲
wire        rd_data_vld_dac       ;// 空闲
reg         ready_dac             ;
//DAC和IIC的控制信号定义  
wire [7:0]  op_wr_data_dac        ;
wire [4:0]  cmd_dac               ;
wire        cmd_vld_dac           ;
reg  [7:0]  op_rd_data_dac        ;
reg         op_rd_data_vld_dac    ;
reg         rev_ack_dac           ;
reg         done_dac              ;

// 固定端口
assign reg_addr_dac = 8'h00; // 读DAC数据寄存器地址
assign reg_addr_vld_dac = 1'b0; // 寄存器地址有效信号线
assign rd_req_dac = 1'b0; // DAC读请求
//////////////////////////////   EEPROM  //////////////////////////////////////////////////
//EEPROM和顶层的控制信号定义
reg         wr_req_eeprom         ;
reg         rd_req_eeprom         ;
reg  [7:0]  reg_addr_eeprom       ;
reg         reg_addr_vld_eeprom   ;
reg  [7:0]  wr_data_eeprom        ;
reg         wr_data_vld_eeprom    ;
reg  [4:0]  wr_bytes_eeprom       ;
wire [7:0]  rd_data_eeprom        ;
wire        rd_data_vld_eeprom    ;
reg  [4:0]  rd_bytes_eeprom       ;
reg         ready_eeprom          ;
//EEPROM和IIC的控制信号定义 
wire [7:0]  op_wr_data_eeprom     ;
wire [4:0]  cmd_eeprom            ;
wire        cmd_vld_eeprom        ;
reg  [7:0]  op_rd_data_eeprom     ;
reg         op_rd_data_vld_eeprom ;
reg         rev_ack_eeprom        ;
reg         done_eeprom           ;

//////////////////////////////   IIC  //////////////////////////////////////////////////
reg  [7:0]  wr_data_iic           ;
reg  [4:0]  cmd_iic               ;
reg         cmd_vld_iic           ;
wire [7:0]  rd_data_iic           ;
wire        rd_data_vld_iic       ;
wire        rev_ack_iic           ;
wire        done_iic              ;

//////////////////////////////   其它控制信号  //////////////////////////////////////////////////
wire        IIC_IDLE              ; // IIC空闲信号线
wire        adc_time              ; // ADC采样时间
wire        dac_time              ; // DAC采样时间
wire        eeprom_time           ; // EEPROM读写时间



//////////////////////////////   判断IIC是否空闲，分配使用情况  //////////////////////////////////////////////////
assign      IIC_IDLE = ready_adc && ready_dac && ready_eeprom; // IIC空闲信号线表示没设备占用IIC
////分配情况还得依据题目

// ADC采样，连续性
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)begin
        rd_req_adc <= 1'b0;
    end else if (adc_time)begin
        rd_req_adc <= 1'b1; // 读请求
    end else begin
        rd_req_adc <= 1'b0;
    end
end

always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)begin
        rd_data_adc_r <= 8'h00;
    end else if (rd_data_vld_adc) begin
        rd_data_adc_r <= rd_data_adc; // 读取ADC数据
    end else begin
        rd_data_adc_r <= rd_data_adc_r; // 保留ADC数据
    end
end

// DAC写数据
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
        wr_req_dac <= 1'b0;
        wr_data_dac <= 8'h00; // DAC数据寄存器
        wr_data_vld_dac <= 1'b0; // DAC数据有效信号线
    end else if (dac_time) begin
        wr_req_dac <= 1'b1; // 写请求
        wr_data_dac <= in_wr_data; // 写入DAC数据
        wr_data_vld_dac <= in_wr_data_vld; // DAC数据有效信号线
    end else begin
        wr_req_dac <= 1'b0;
        wr_data_dac <= wr_data_dac; // 保留DAC数据
        wr_data_vld_dac <= 1'b0; // DAC数据有效信号线
    end
end

// EEPROM读写控制
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        wr_req_eeprom <= 1'b0;
        rd_req_eeprom <= 1'b0;
        reg_addr_eeprom <= 8'h00;
        reg_addr_vld_eeprom <= 1'b0;
        wr_data_eeprom <= 8'h00;
        wr_data_vld_eeprom <= 1'b0;
        wr_bytes_eeprom <= 5'h0;
        rd_bytes_eeprom <= 5'h0;
    end else if(eeprom_time) begin
        if(control == EEPROM_W) begin
            // EEPROM写操作
            wr_req_eeprom <= 1'b1;
            rd_req_eeprom <= 1'b0;
            reg_addr_eeprom <= 8'h00; // 地址可根据需求修改
            reg_addr_vld_eeprom <= 1'b1;
            wr_data_eeprom <= in_wr_data;
            wr_data_vld_eeprom <= in_wr_data_vld;
            wr_bytes_eeprom <= 5'd1; // 默认写1字节
        end else if(control == EEPROM_R) begin
            // EEPROM读操作
            wr_req_eeprom <= 1'b0;
            rd_req_eeprom <= 1'b1;
            reg_addr_eeprom <= 8'h00; // 地址可根据需求修改
            reg_addr_vld_eeprom <= 1'b1;
            rd_bytes_eeprom <= 5'd1; // 默认读1字节
        end
    end else begin
        wr_req_eeprom <= 1'b0;
        rd_req_eeprom <= 1'b0;
        reg_addr_vld_eeprom <= 1'b0;
        wr_data_vld_eeprom <= 1'b0;
    end
end


// 根据情况控制，IIC输入指令等寄存器
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
        cmd_iic <= 5'b0; // 指令寄存器
        cmd_vld_iic <= 1'b0; // 指令有效信号线
        wr_data_iic <= 8'h00; // 写入数据寄存器
        // ADC
            op_rd_data_adc <= 8'd0; 
            op_rd_data_vld_adc <= 'b0;
            done_adc <= 'b0;
            rev_ack_adc <= 'b0;
        // DAC
            op_rd_data_dac <= 8'd0; 
            op_rd_data_vld_dac <= 'b0;
            done_dac <= 'b0;
            rev_ack_dac <= 'b0;
        // EEPROM
            op_rd_data_eeprom <= 8'd0; 
            op_rd_data_vld_eeprom <= 'b0;
            done_eeprom <= 'b0;
            rev_ack_eeprom <= 'b0;
    end else begin
        if (adc_time) begin
            cmd_iic <= cmd_adc;
            cmd_vld_iic <= cmd_vld_adc;
            wr_data_iic <= op_wr_data_adc;
            op_rd_data_adc <= rd_data_iic;
            op_rd_data_vld_adc <= rd_data_vld_iic;
            rev_ack_adc <= rev_ack_iic;   // 在adc_time条件下
            done_adc <= done_iic;
        end else if (dac_time) begin
            cmd_iic <= cmd_dac;
            cmd_vld_iic <= cmd_vld_dac;
            wr_data_iic <= op_wr_data_dac;
            op_rd_data_dac <= rd_data_iic;
            op_rd_data_vld_dac <= rd_data_vld_iic;
            rev_ack_dac <= rev_ack_iic;   // 在dac_time条件下
            done_dac <= done_iic;
        end else if (eeprom_time) begin
            cmd_iic <= cmd_eeprom;
            cmd_vld_iic <= cmd_vld_eeprom;
            wr_data_iic <= op_wr_data_eeprom;
            op_rd_data_eeprom <= rd_data_iic;
            op_rd_data_vld_eeprom <= rd_data_vld_iic;
            rev_ack_eeprom <= rev_ack_iic;   // 在eeprom_time条件下
            done_eeprom <= done_iic;
        end else begin
            cmd_iic <= 5'b0; // 指令寄存器
            cmd_vld_iic <= 1'b0; // 指令有效信号线
            wr_data_iic <= 8'h00; // 写入数据寄存器
            // ADC
                op_rd_data_adc <= op_rd_data_adc; 
                op_rd_data_vld_adc <= 'b0;
                done_adc <= 'b0;
                rev_ack_adc <= 'b1;
            // DAC
                op_rd_data_dac <= op_rd_data_dac; 
                op_rd_data_vld_dac <= 'b0;
                done_dac <= 'b0;
                rev_ack_dac <= 'b1;
            // EEPROM
                op_rd_data_eeprom <= op_rd_data_eeprom; 
                op_rd_data_vld_eeprom <= 'b0;
                done_eeprom <= 'b0;
                rev_ack_eeprom <= 'b1;
        end
    end
end


adc  adc_inst (
  .clk(sys_clk),
  .rst_n(rst_n),
  .wr_req(wr_req_adc),
  .rd_req(rd_req_adc),
  .device_id(device_id_adc),
  .reg_addr(reg_addr_adc),
  .reg_addr_vld(reg_addr_vld_adc),
  .wr_data(wr_data_adc),
  .wr_data_vld(wr_data_vld_adc),
  .rd_data_adc(rd_data_adc),
  .rd_data_vld(rd_data_vld_adc),
  .ready(ready_adc),

  
  .cmd_adc(cmd_adc),
  .cmd_vld_adc(cmd_vld_adc),
  .op_wr_data_adc(op_wr_data_adc),
  .op_rd_data_adc(op_rd_data_adc),
  .op_rd_data_vld_adc(op_rd_data_vld_adc),
  .rev_ack(rev_ack_adc),
  .done_adc(done_adc)
);

dac  dac_inst (
  .clk(sys_clk),
  .rst_n(rst_n),
  .wr_req(wr_req_dac),
  .rd_req(rd_req_dac),
  .device_id(device_id_dac),
  .reg_addr(reg_addr_dac),
  .reg_addr_vld(reg_addr_vld_dac),
  .wr_data(wr_data_dac),
  .wr_data_vld(wr_data_vld_dac),
  .rd_data(rd_data_dac),
  .rd_data_vld(rd_data_vld_dac),
  .ready(ready_dac),

  .op_wr_data_dac(op_wr_data_dac),
  .cmd_dac(cmd_dac),
  .cmd_vld_dac(cmd_vld_dac),
  .op_rd_data_dac(op_rd_data_dac),
  .op_rd_data_vld_dac(op_rd_data_vld_dac),
  .rev_ack_dac(rev_ack_dac),
  .done_dac(done_dac)
);

eeprom  eeprom_inst (
  .clk(sys_clk),
  .rst_n(rst_n),
  .wr_req(wr_req_eeprom),
  .rd_req(rd_req_eeprom),
  .device_id(device_id_eeprom),
  .reg_addr(reg_addr_eeprom),
  .reg_addr_vld(reg_addr_vld_eeprom),
  .wr_data(wr_data_eeprom),
  .wr_data_vld(wr_data_vld_eeprom),
  .wr_bytes(wr_bytes_eeprom),
  .rd_data(rd_data_eeprom),
  .rd_data_vld(rd_data_vld_eeprom),
  .rd_bytes(rd_bytes_eeprom),
  .ready(ready_eeprom),

  .cmd_eeprom(cmd_eeprom),
  .cmd_vld_eeprom(cmd_vld_eeprom),
  .op_wr_data_eeprom(op_wr_data_eeprom),
  .op_rd_data_eeprom(op_rd_data_eeprom),
  .op_rd_data_vld_eeprom(op_rd_data_vld_eeprom),
  .rev_ack_eeprom(rev_ack_eeprom),
  .done_eeprom(done_eeprom)
);

i2c  i2c_inst (
  .clk(sys_clk),
  .rst_n(rst_n),
  .cmd(cmd_iic),
  .cmd_vld(cmd_vld_iic),
  .wr_data(wr_data_iic),
  .rd_data(rd_data_iic),
  .rd_data_vld(rd_data_vld_iic),
  .rev_ack(rev_ack_iic),
  .done(done_iic),

  .scl(scl),
  .sda(sda)
);

endmodule