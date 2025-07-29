/*==============================================
* Function Name  : inst_decode.v
* Description    : 指令解码模块，处理上位机发送的指令数据，并根据指令类型进行相应的操作。
*                  包括指令分类、指令处理、数据输入输出等功能。
* input port     : 具体端口说明见下方注释
* output port    : 具体端口说明见下方注释
* Author         : ADBD
//==============================================*/
`include "E:/NEC/FPGA/SPI/src/top_define.v"
module inst_dec(
    input   wire                                sys_clk,            // 时钟信号
    input   wire                                rst_n,              // 复位信号

    input   wire [`DATA_WIDTH-1:0]              inst_data,          // 上位机输入指令
    input   wire                                inst_data_valid,    // 上位机指令数据有效信号
    output  reg                                 inst_data_ready,    // 上位机指令数据准备好信号

    output  reg  [`DATA_WIDTH-1:0]              instr_data_out,     // 输出数据到设备
    output  reg                                 device_enable,      // 设备使能信号
    output  reg  [`DEVICE_CONTROL_WIDTH/2-2:0]  device_control,     // 设备控制信号片选
    output  reg                                 data_out_vld,       // 输出数据有效信号到设备
    input   wire                                data_out_ready      // 设备数据输出准备好信号

);
localparam  IDLE             = `SPI_STATE'b0000_0000; // 空闲状态
localparam  START            = `SPI_STATE'b0000_0001; // 开始状态
localparam  Decode           = `SPI_STATE'b0000_0010; // 指令解码状态
localparam  OVER             = `SPI_STATE'b0000_0100; // 结束状态

reg [`SPI_STATE-1:0]    cstate, nstate; // 状态寄存器
reg [`DATA_WIDTH-1:0]   inst_data_r;// 指令读取寄存器

wire inst = inst_data_r[15:8] == 8'hFF; // 判断是否为指令集
// wire A_class = inst_data_r[7:4] == `A_Class; // 判断是否为控制指令
// wire B_class = inst_data_r[7:4] == `B_Class; // 判断是否为数据指令
wire Turn_ON_OFF = inst_data_r[3]; // 判断是否为开启指令
wire [2:0] Device_ID = inst_data_r[2:0];

wire IDLE_START     = (cstate == IDLE) && inst_data_valid; // 空闲状态下开始指令解码
wire START_Decode   = (cstate == START) && inst; // 开始状态下指令解码
wire START_OVER     = (cstate == START) && !inst;
wire Decode_OVER    = (cstate == Decode); // 指令解码后只需要一个周期控制
wire OVER_IDLE      = (cstate == OVER) && data_out_ready; // 结束状态下数据输出准备好信号

// 指令暂存
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        inst_data_r <= 0;
    end else if (inst_data_valid) begin
        inst_data_r <= inst_data;
    end else if (cstate == OVER) begin
        inst_data_r <= 16'd0; // 结束状态后清空指令寄存器
    end else begin
        inst_data_r <= inst_data_r; // 保持当前指令
    end
end

// 上位机应答信号
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        inst_data_ready <= 1'b0; // 复位时指令数据不准备好
    end else if (IDLE_START) begin
        inst_data_ready <= 1'b1; // 指令数据有效时准备好
    end else begin
        inst_data_ready <= 1'b0; // 指令数据无效时不准备好
    end
end

// 数据处理·
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        instr_data_out <= 0; // 复位时数据输出为0 
        device_control <= 0; // 复位时设备控制信号为0
        device_enable <= 1'b0; // 复位时设备使能信号为0
    end else if (cstate == Decode) begin
        device_control <= Device_ID;
        device_enable  <= Turn_ON_OFF;
        instr_data_out <= instr_data_out;
    end else if (START_OVER) begin
        device_control <= device_control; // 结束状态后清空设备控制信号
        device_enable <= device_enable; // 结束状态后设备使能信号为0
        instr_data_out <= inst_data_r; // 结束状态后数据输出为0
    end else if (cstate == OVER)begin
        device_control <= 0; // 结束状态后清空设备控制信号
        device_enable <= 1'b0; // 结束状态后设备使能信号为0
        instr_data_out <= 16'd0; // 结束状态后数据输出为0
    end else begin
        device_control <= device_control; // 保持当前设备控制信号
        device_enable <= device_enable; // 保持当前设备使能信号
        instr_data_out <= instr_data_out; // 保持当前数据输出
    end
end

// 输出有效信号
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
        data_out_vld <= 'b0;
    end else if (cstate == Decode) begin
        data_out_vld <= 1'b1; // 指令解码状态下数据输出有效
    end else if (START_OVER) begin
        data_out_vld <= 1'b1;
    end else begin
        data_out_vld <= 'b0; // 保持当前数据输出有效状态
    end
end


// 状态机第二阶
always @(*) begin
    case (cstate)
        IDLE: begin
            if (IDLE_START)begin
                nstate = START; // 进入指令解码状态
            end else begin
                nstate = IDLE; // 保持在空闲状态
            end
        end
        START: begin
            if (START_Decode) begin
                nstate = Decode; // 进入指令解码状态
            end else if (START_OVER) begin
                nstate = OVER; // 进入结束状态
            end else begin
                nstate = START; // 保持在开始状态
            end
        end
        Decode: begin
            if (Decode_OVER) begin
                nstate = OVER; // 结束状态
            end else begin
                nstate = Decode;
            end
        end
        OVER: begin
            if (OVER_IDLE)begin
                nstate = IDLE; // 结束后回到空闲状态
            end else begin
                nstate = OVER; // 保持在结束状态
            end
        end
        default: begin
            nstate = IDLE; // 默认状态为IDLE
        end
    endcase
end

// 状态机第一阶
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        cstate <= IDLE;
    end else begin
        cstate <= nstate;
    end
end

endmodule
