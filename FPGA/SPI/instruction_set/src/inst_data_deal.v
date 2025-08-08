/*==============================================
* Function Name  : inst_data_deal.v
* Description    : 接收指令解码器过来的数据，并进行相应的处理。
* input port     : 具体端口说明见下方注释
* output port    : 具体端口说明见下方注释
* Author         : ADBD
//==============================================*/
`include "E:/NEC/FPGA/SPI/src/top_define.v"
module inst_data_deal(
    input  wire                                sys_clk,                     // 时钟信号
    input  wire                                rst_n,                       // 复位信号
    // 从指令解码器过来的数据
    input  wire  [`DATA_WIDTH-1:0]              instr_data_out,             // 输出数据到设备
    input  wire                                 device_enable,              // 设备使能信号
    input  wire  [`DEVICE_CONTROL_WIDTH/2-2:0]  device_control,             // 设备控制信号片选
    input  wire                                 data_out_vld,               // 输出数据有效信号到设备
    output reg                                  data_out_ready,             // 设备数据输出准备好信号

    // 输出给时钟模块的信号
    output wire             enable,                                                 // 模块启动信号
    output reg              valid,                                                  // 输入有效信号
    input  wire             ready,                                                  // 输出就绪信号，表示模块已准备好接收数据

    output reg  [2:0]       clk_control_num,                                        // 需要控制的时钟总数量
    output reg  [2:0]       clk_choise,                                             // 时钟选择信号，0表示全部时钟，
                                                                                    // 1表示时钟1，2表示时钟2，3表示时钟3
    output  reg  [7:0]      frq_mult_int,                                           // 频率倍频系数，正数部分，对于全部时钟
    output  reg  [7:0]      frq_mult_float,                                         // 频率倍频系数，小数部分，对于全部时钟
    output  reg  [7:0]      frq_div_int,                                            // 频率分频系数,整数部分，复用，可对所有时钟，也可以对某个时钟
    output  reg  [7:0]      frq_div_float,                                          // 频率分频系数,小数部分，对于时钟1才有小数分频
    output  reg  [31:0]     frq_phase_value,                                        // 频率相位值，对各自的时钟进行设置
    input   wire            accomplish,                                             // 表示写寄存器全部完成

    // IDREAD处理       
    output  reg             ID_READ_Flag,                                           // ADC数据传递标志
    // 将ADC的数据传递给STM32       
    output  reg             ADC_Trans_Flag,                                         // ADC数据传递标志
    // 接收到STM32数据输出给DAC     
    output  reg             default_mode,                                           // 1：默认情况，0：取消默认情况
    output  reg             dac_data_in_valid,                                      // DAC数据输入有效信号
    // 开启FIR低通滤波器——ADC                                       
    output  reg             FIR_ADC_Enable,                                         // 开启FIR低通滤波器——ADC
    // 开启FIR低通滤波器——DAC       
    output  reg             FIR_DAC_Enable,                                         // 开启FIR低通滤波器——DAC
    // 开启鉴频鉴相器       
    output  reg             Freq_Phase_Enable                                       // 开启鉴频鉴相器
);
reg [2:0] cstate, nstate; // 状态寄存器
localparam IDLE      = 3'b000;
localparam START     = 3'b001;// 在START里面，单次控制可以处理完的直接到DONE，需要数据传输的就到对应的模式
localparam Time_Mode = 3'b010;// 在这模式里面根据要控制的时钟的数量进行控制
localparam DAC_Mode  = 3'b011;// 直接转运数据，直到说要结束转运
localparam DONE      = 3'b100;

reg [2:0] time_cstate,time_nstate; // 时间模式状态寄存器
localparam CLK_NUM  = 3'b001;  // 记录时钟数量
localparam CLK_ALL  = 3'b010;  // 控制全部时钟的 整数+小数倍频->整数分频
localparam CLK_FRQ  = 3'b011;  // 控制每个时钟的频率
localparam CLK_PHA  = 3'b100;  // 控制每个时钟的相位
localparam CLK_OVER = 3'b101;  // 结束状态

// reg  [`DATA_WIDTH-1:0]              instr_data_out_r;             // 输出数据到设备
reg                                 device_enable_r;              // 设备使能信号
reg  [`DEVICE_CONTROL_WIDTH/2-2:0]  device_control_r;             // 设备控制信号片选

// 大状态机的状态转换条件
wire IDLE_START = (cstate == IDLE) && data_out_vld; // 空闲状态下开始指令解码
wire START_DONE = (cstate == START) && (device_control_r <= 3'h5); // 开始状态下指令解码完成
wire START_Time_Mode = (cstate == START) && (device_control_r == 3'h6) && device_enable_r; // 开始状态下进入时间模式
wire START_DAC_Mode = (cstate == START) && (device_control_r == 3'h7); // 开始状态下进入DAC模式
wire Time_Mode_DONE = (cstate == Time_Mode) && (time_cstate == CLK_OVER) && accomplish; // 时间模式下完成
wire DAC_Mode_DONE = cstate == DAC_Mode; // DAC模式下

reg [4:0] time_cnt;
// 时钟调整状态机的状态条件
wire cstate_Time_Mode = (cstate == Time_Mode);
wire IDLE_CLK_NUM     = (time_cstate == IDLE) && cstate_Time_Mode; // 时钟数量状态
wire CLK_NUM_CLK_ALL  = (time_cstate == CLK_NUM) && time_cnt == 5'd1; // 时钟数量状态下进入全部时钟状态
wire CLK_ALL_CLK_FRQ  = (time_cstate == CLK_ALL) && time_cnt == 5'd3; 
wire CLK_FRQ_FLK_PHA  = (time_cstate == CLK_FRQ) && ((time_cnt-5'd3) == clk_control_num << 1); // 时钟频率状态
wire CLK_PHA_CLK_OVER = (time_cstate == CLK_PHA) && ((time_cnt-5'd3) == clk_control_num << 2);
wire CLK_OVER_IDLE    = (time_cstate == CLK_OVER) && accomplish; // 结束状态下数据输出准备好

assign enable = (cstate == Time_Mode);
// 数据接收到信号
always @(*) begin
    if (!rst_n) begin
        data_out_ready = 1'b0; // 复位时指令数据不准备好
    end else if (cstate == IDLE) begin
        data_out_ready = 1'b1; // 空闲状态或结束状态下数据输出准备好
    end else if (cstate == DAC_Mode && device_enable_r) begin
        data_out_ready = 1'b1; 
    end else if (cstate == Time_Mode) begin
        case (time_cstate)
            IDLE,CLK_OVER: data_out_ready = 1'b0;
            CLK_NUM,CLK_ALL: begin
                if (valid) begin
                    data_out_ready = 1'b0; 
                end else begin
                    data_out_ready = 1'b1; 
                end
            end
            CLK_FRQ,CLK_PHA: begin
                if (valid)begin
                    data_out_ready = 1'b0;
                end else begin
                    data_out_ready = 1'b1; 
                end
            end
            default: begin
                data_out_ready = 1'b0;
            end
        endcase
    end else begin
        data_out_ready = 1'b0; // 保持当前状态
    end
end

// 数据缓存
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
        device_enable_r  <= 'b0;
        device_control_r <= 3'd0;
    end else if (data_out_vld)begin
        device_enable_r  <= device_enable;
        device_control_r <= device_control;
    end else if (cstate == DONE) begin
        device_enable_r  <= 'b0;
        device_control_r <= 3'd0;
    end else begin
        device_enable_r  <= device_enable_r;  // 保持当前使能信号
        device_control_r <= device_control_r; // 保持当前控制信号
    end
end

// 3'h1,IDREAD处理
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        ID_READ_Flag <= 1'b0; 
    end else if ((cstate == START) &&  (device_control_r == `IDREAD) && device_enable_r) begin// 单次有效
        ID_READ_Flag <= 1'b1; 
    end else begin
        ID_READ_Flag <= 1'b0; // 单次有效
    end
end

// 3'h2,ADC处理
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        ADC_Trans_Flag <= 1'b0; // 复位时ADC传输标志清零
    end else if ((cstate == START) && (device_control_r == `ADC_Read)) begin
        if (device_enable_r)begin
            ADC_Trans_Flag <= 1'b1; 
        end else begin
            ADC_Trans_Flag <= 1'b0; 
        end
    end else begin
        ADC_Trans_Flag <= ADC_Trans_Flag; // 保持当前ADC传输标志
    end
end

// 3'h3,FIR_ADC处理
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        FIR_ADC_Enable <= 1'b0; // 复位时ADC传输标志清零
    end else if ((cstate == START) && (device_control_r == `FIR_ADC)) begin
        if (device_enable_r)begin
            FIR_ADC_Enable <= 1'b1; 
        end else begin
            FIR_ADC_Enable <= 1'b0; 
        end
    end else begin
        FIR_ADC_Enable <= FIR_ADC_Enable; // 保持当前ADC传输标志
    end
end

// 3'h4,FIR_DAC处理
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        FIR_DAC_Enable <= 1'b0; // 复位时ADC传输标志清零
    end else if ((cstate == START) && (device_control_r == `FIR_DAC)) begin
        if (device_enable_r)begin
            FIR_DAC_Enable <= 1'b1; 
        end else begin
            FIR_DAC_Enable <= 1'b0; 
        end
    end else begin
        FIR_DAC_Enable <= FIR_DAC_Enable; // 保持当前ADC传输标志
    end
end

// 3'h5,PFD处理
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        Freq_Phase_Enable <= 1'b0; // 复位时ADC传输标志清零
    end else if ((cstate == START) && (device_control_r == `PFD)) begin
        if (device_enable_r)begin
            Freq_Phase_Enable <= 1'b1; 
        end else begin
            Freq_Phase_Enable <= 1'b0; 
        end
    end else begin
        Freq_Phase_Enable <= Freq_Phase_Enable; // 保持当前ADC传输标志
    end
end

// 3'h7,DAC_Write处理
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
        default_mode        <=   'b1;    // 1：默认情况，0：取消默认情况
        dac_data_in_valid   <=   'b0;    // DAC数据输入有效信号
    end else if (cstate == DAC_Mode) begin
        if (device_enable_r) begin
            default_mode        <=   'b0;    // 1：默认情况，0：取消默认情况
            dac_data_in_valid   <=   'b1;    // DAC数据输入有效信号
        end else begin
            default_mode        <=   'b1;    // 1：默认情况，0：取消默认情况
            dac_data_in_valid   <=   'b0;    // DAC数据输入有效信号
        end
    end else begin
        default_mode        <=   default_mode; // 保持当前默认模式
        dac_data_in_valid   <=   dac_data_in_valid; // 保持当前DAC数据输入有效信号
    end
end

// 3'h6 控制计数器
always @(posedge sys_clk or negedge rst_n)begin
    if (!rst_n)begin
        time_cnt <= 5'd0; 
    end else if (cstate == Time_Mode && data_out_vld)begin
        time_cnt <= time_cnt + 1'b1; // 计数器自增
    end else if (time_cstate == CLK_OVER) begin
        time_cnt <= 5'd0; // 结束状态下计数器清零
    end else begin
        time_cnt <= time_cnt; // 保持当前计数器值
    end
end
// 3'h6,Time数据流控制 clk_control_num
always @(posedge sys_clk or negedge rst_n)begin
    if (!rst_n)begin
        clk_control_num <= 3'd0;
    end else if (time_cstate == CLK_NUM && data_out_vld)begin
        clk_control_num <= instr_data_out[2:0];
    end else if (time_cstate == IDLE) begin
        clk_control_num <= 3'd0;
    end else begin
        clk_control_num <= clk_control_num;
    end 
end
// 3'h6,Time数据流控制 clk_choise
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
        clk_choise <= 3'd0;
    end else if (time_cstate == CLK_ALL)begin
        clk_choise <= 3'd0;
    end else if ((time_cstate == CLK_FRQ || time_cstate == CLK_PHA) && time_cnt[0] && data_out_vld) begin
        clk_choise <= instr_data_out[2:0];
    end else begin
        clk_choise <= clk_choise;
    end
end
// 3'h6,Time数据流控制 frq_mult_int frq_mult_float
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
        frq_mult_int   <= 8'd0;
        frq_mult_float <= 8'd0;
    end else if (time_cstate == CLK_ALL && data_out_vld && time_cnt == 5'd1) begin
        frq_mult_float <= instr_data_out[7:0]; // 时钟1的整数倍频
        frq_mult_int   <= instr_data_out[15:8];
    end else if (time_cstate == CLK_OVER) begin
        frq_mult_int   <= 8'd0;
        frq_mult_float <= 8'd0;
    end else begin
        frq_mult_int   <= frq_mult_int;
        frq_mult_float <= frq_mult_float;
    end
end
// 3'h6,Time数据流控制 frq_div_int frq_div_float
always @(posedge sys_clk or negedge rst_n)begin
    if (!rst_n)begin
        frq_div_int   <= 8'd0;
        frq_div_float <= 8'd0;
    end else if (time_cstate == CLK_ALL && data_out_vld && time_cnt == 5'd2) begin
        frq_div_int   <= instr_data_out[15:8];
    end else if (time_cstate == CLK_FRQ && data_out_vld && !time_cnt[0])begin
        frq_div_int   <= instr_data_out[15:8]; // 时钟1的整数分频
        frq_div_float <= instr_data_out[7:0];  // 时钟1
    end else if (time_cstate == CLK_OVER)begin
        frq_div_int   <= 8'd0;
        frq_div_float <= 8'd0;
    end else begin
        frq_div_int   <= frq_div_int;
        frq_div_float <= frq_div_float;
    end
end
// 3'h6,Time数据流控制 frq_phase_value
always @(posedge sys_clk or negedge rst_n)begin
    if (!rst_n)begin
        frq_phase_value <= 32'd0;
    end else if (time_cstate == CLK_PHA && data_out_vld && !time_cnt[0])begin
        frq_phase_value <= {16'd0,instr_data_out};
    end else if (time_cstate == CLK_OVER)begin
        frq_phase_value <= 32'd0;
    end else begin
        frq_phase_value <= frq_phase_value;
    end
end
reg valid_flag, valid_flag1;// 用于标记是否需要更新valid信号
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
        valid_flag <= 1'b0; // 复位时valid标志清零
    end else if ((time_cstate == CLK_FRQ || time_cstate == CLK_PHA) && time_cnt[0] && time_cnt > 5'd3)begin
        valid_flag <= 1'b1;
    end else begin
        valid_flag <= 1'b0; // 保持当前valid标志
    end
end

always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
        valid_flag1 <= 1'b0; // 复位时valid标志清零
    end else begin
        valid_flag1 <= valid_flag; // 保持当前valid标志
    end
end

// 3'h6,Time数据流控制 valid
always @(posedge sys_clk or negedge rst_n)begin
    if (!rst_n)begin
        valid <= 1'b0;
    end else if (ready) begin
        valid <= 1'd0;
    end else if (CLK_ALL_CLK_FRQ || CLK_PHA_CLK_OVER)begin
        valid <= 1'b1;
    end else if (time_cstate == CLK_FRQ || time_cstate == CLK_PHA)begin
        valid <= ~valid_flag1 & valid_flag; // 当valid_flag为1时，更新valid信号
    end else begin
        valid <= 'b0; // 保持当前有效信号
    end
end

// 时钟调整状态机第二阶
always @(*) begin
    case (time_cstate)
        IDLE: begin
            if (IDLE_CLK_NUM)begin
                time_nstate = CLK_NUM;
            end else begin
                time_nstate = IDLE;
            end
        end
        CLK_NUM: begin
            if (CLK_NUM_CLK_ALL)begin
                time_nstate = CLK_ALL;
            end else begin
                time_nstate = CLK_NUM;
            end        
        end
        CLK_ALL:begin
            if (CLK_ALL_CLK_FRQ)begin
                time_nstate = CLK_FRQ;
            end else begin
                time_nstate = CLK_ALL; // 保持当前状态
            end
        end
        CLK_FRQ:begin
            if (CLK_FRQ_FLK_PHA) begin
                time_nstate = CLK_PHA; // 频率状态下进入相位状态
            end else begin
                time_nstate = CLK_FRQ; // 保持当前状态
            end
        end
        CLK_PHA: begin
            if (CLK_PHA_CLK_OVER) begin
                time_nstate = CLK_OVER;
            end else begin
                time_nstate = CLK_PHA; // 保持当前状态
            end
        end
        CLK_OVER:begin
            if (CLK_OVER_IDLE) begin
                time_nstate = IDLE;
            end else begin
                time_nstate = CLK_OVER; // 保持当前状态
            end
        end
        default:begin
            time_nstate = IDLE;
        end
    endcase
end
// 时钟调整状态机第一阶
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        time_cstate <= IDLE; // 复位时状态为IDLE
    end else begin
        time_cstate <= time_nstate; // 状态转移
    end
end

// 大状态机的第二阶
always @(*) begin
    case (cstate)
        IDLE: begin
            if (IDLE_START) begin
                nstate = START; // 空闲状态下开始指令解码
            end else begin
                nstate = IDLE; // 保持空闲状态
            end
        end
        START:begin
            if (START_DONE)begin
                nstate = DONE;
            end else if (START_Time_Mode)begin
                nstate = Time_Mode;
            end else if (START_DAC_Mode)begin
                nstate =  DAC_Mode;
            end else begin
                nstate = START;
            end
        end
        Time_Mode: begin
            if (Time_Mode_DONE) begin
                nstate = DONE; // 时间模式下完成
            end else begin
                nstate = Time_Mode; // 保持时间模式状态
            end
        end
        DAC_Mode: begin
            if (DAC_Mode_DONE) begin
                nstate = DONE; // DAC模式下完成
            end else begin
                nstate = DAC_Mode; // 保持DAC模式状态
            end
        end
        default: begin
            nstate = IDLE; // 其他状态回到空闲状态
        end
    endcase
end
// 大状态机的第一阶
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        cstate <= IDLE; // 复位时状态为IDLE
    end else begin
        cstate <= nstate; // 状态转移
    end
end

endmodule
