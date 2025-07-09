/*==============================================
* Function Name  : instruction_decode.v
* Description    : 指令解码模块，处理上位机发送的指令数据，并根据指令类型进行相应的操作。
*                  包括指令分类、指令处理、数据输入输出等功能。
* input port     : 具体端口说明见下方注释
* output port    : 具体端口说明见下方注释
* Author         : ADBD
//==============================================*/
`include "E:/NEC/FPGA/SPI/src/top_define.v"
module instruction_decode(
    input   wire                        clk,// 时钟信号
    input   wire                        rst_n,// 复位信号

    input   wire [`DATA_WIDTH-1:0]      instruction_data,// 上位机输入指令
    input   wire                        instruction_data_valid,// 上位机指令数据有效信号
    output  wire                        instruction_data_ready,// 上位机指令数据准备好信号

    output  reg  [`DATA_WIDTH-1:0]      instruction_data_return,// 输出指令数据到上位机
    output  reg                         instruction_data_return_vld,// 输出指令数据有效信号到上位机
    input   wire                        instruction_data_return_req,// 上位机请求指令数据返回信号

    input   wire [`ADDR_WIDTH-1:0]      FIFO_depth,// FIFO深度

    input   wire [`DATA_WIDTH-1:0]      data_in,// 数据输入信号
    input   wire                        data_in_valid,// 数据输入有效信号
    output  reg                         data_in_ready,// 数据输入准备好信号

    input  wire                         data_out_req,// 请求数据输出信号
    output  reg  [`DATA_WIDTH-1:0]      data_out,// 数据输出信号
    output  reg                         data_out_valid,// 数据输出有效信号

    output  reg  [`DEVICE_CONTROL_WIDTH/2-1:0] device_control,// 设备控制信号片选
    output  reg  [`DEVICE_CONTROL_WIDTH/2-1:0] device_freq_control,// 设备控制数据
    output  reg  [`DEVICE_CONTROL_WIDTH/4-1:0] device_freq// 设备控制数据片选
);

localparam IDLE                     = `SPI_STATE'b0000_0001;// 空闲状态
localparam INSTRUCTION_MODE         = `SPI_STATE'b0000_0010;// 指令模式，判断指令类型
localparam INSTRUCTION_DEAL         = `SPI_STATE'b0000_0100;// 指令处理状态
localparam INSTRUCTION_MODE_DATA    = `SPI_STATE'b0000_1000;// 指令模式下的数据模式，指令模式下的数据流向控制
localparam OVER                     = `SPI_STATE'b0001_0000;// 结束状态

reg [`DATA_WIDTH-1:0] instruction_data_reg;// 指令寄存器
reg [`SPI_STATE-1:0]  cstate,nstate;// 指令状态寄存器
reg [`DATA_WIDTH-1:0] data_in_reg;// 数据输入寄存器
reg [1:0]             data_wr_allow;// 上位机写入数据允许信号
reg [1:0]             data_re_allow;// 向上位机返回数据允许信号

wire IDLE_CLASSIFICATION = (cstate == IDLE) && (instruction_data_reg[15:8] == 8'hD0);
wire INSTR_NEED_DATA     = (cstate == INSTRUCTION_MODE) && (instruction_data_reg[7:4] == 4'hE);// 判断指令是否需要数据交换
wire INSTR_DEAL          = (cstate == INSTRUCTION_MODE) && (instruction_data_reg[7:4] == 4'hA || instruction_data_reg[7:4] == 4'hB);// 判断指令是否需要处理

assign instruction_data_ready = cstate == OVER;// 上位机指令数据准备好信号

// 指令数据读取缓存寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)begin
        instruction_data_reg <= {`DATA_WIDTH{1'b0}};
    end else if ((cstate == IDLE) && instruction_data_valid) begin//指令数据有效时，读取指令或数据
        instruction_data_reg <= instruction_data;
    end
end

// Module 1: Handle data_re_allow register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_re_allow <= 2'b00;
    end else if (cstate == INSTRUCTION_MODE_DATA && instruction_data_return_req) begin
        case (instruction_data_reg[3:0])
            4'hA, 4'h8, 4'h0: data_re_allow <= 2'b01;
            4'hF: data_re_allow <= 2'b10;
            default: data_re_allow <= 2'b00;
        endcase
    end else if (data_re_allow == 2'b01) begin
        data_re_allow <= 2'b00;
    end
end

// Module 2: Handle data_wr_allow register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_wr_allow <= 2'b00;
    end else if (cstate == INSTRUCTION_MODE_DATA && instruction_data_return_req) begin
        case (instruction_data_reg[3:0])
            4'h9: data_wr_allow <= 2'b01;
            4'hD: data_wr_allow <= 2'b10;
            4'hC: data_wr_allow <= 2'b00;
            default: data_wr_allow <= 2'b00;
        endcase
    end else if (data_wr_allow == 2'b01) begin
        data_wr_allow <= 2'b00;
    end
end

// Module 3: Handle data_in_ready register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_in_ready <= 1'b0;
    end else if (cstate == INSTRUCTION_MODE_DATA && instruction_data_return_req) begin
        case (instruction_data_reg[3:0])
            4'h8, 4'hF: data_in_ready <= 1'b1;
            4'hE: data_in_ready <= 1'b0;
            default: data_in_ready <= 1'b0;
        endcase
    end else if (data_re_allow == 2'b01) begin
        data_in_ready <= 1'b0;
    end
end

//输出数据指令寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)begin
        instruction_data_return <= {`DATA_WIDTH{1'b0}};
        instruction_data_return_vld <= 1'b0;
    end else if (|data_re_allow)begin
        instruction_data_return <= data_in_reg;
        instruction_data_return_vld <= 1'b1;
    end else begin
        instruction_data_return_vld <= 1'b0;
    end
end

//外设输入数据
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)begin
        data_in_reg <= {`DATA_WIDTH{1'b0}};
    end else if (cstate == INSTRUCTION_MODE_DATA) begin
        case (instruction_data_reg[3:0])
            4'hA:begin
                data_in_reg <= `SPI_DEVICE_ID;
            end
            4'h0:begin
                data_in_reg <= FIFO_depth;
            end
        endcase
    end else if (data_in_valid) begin
        data_in_reg <= data_in;
    end
end

// 上位机写入数据
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)begin
        data_out <= {`DATA_WIDTH{1'b0}};
        data_out_valid <= 1'b0;
    end else if (|data_wr_allow)begin
        if (instruction_data_reg[`DATA_WIDTH-1:`DATA_WIDTH-2] == 2'b10)begin
            data_out <= instruction_data_reg;
            data_out_valid <= 1'b1;
        end else begin
            data_out <= {`DATA_WIDTH{1'b0}};
            data_out_valid <= 1'b0;
        end
    end else begin
        data_out <= {`DATA_WIDTH{1'b0}};
        data_out_valid <= 1'b0;
    end
end

// 控制指令
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        device_control <= {`DEVICE_CONTROL_WIDTH/2{1'b0}};
        device_freq_control <= {`DEVICE_CONTROL_WIDTH/2{1'b0}};
        device_freq <= {`DEVICE_CONTROL_WIDTH/4{1'b0}};
    end else if (cstate == INSTRUCTION_DEAL)begin
        case (instruction_data_reg[7:4])
            4'hA:begin// 控制指令请求
                if (instruction_data_reg[3])begin
                    device_control[instruction_data_reg[2:0]] <= 1'b1; 
                end else begin
                    device_control[instruction_data_reg[2:0]] <= 1'b0;
                end 
            end
            4'HB:begin
                if (instruction_data_reg[3])begin
                    device_freq_control[instruction_data_reg[2:0]] <= 1'b1; 
                end else begin
                    device_freq_control[instruction_data_reg[2:0]] <= 1'b0;
                end
                device_freq <= instruction_data_reg[`DATA_WIDTH-5:`DATA_WIDTH-8];
            end
        endcase
    end
end

// 指令状态机
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cstate <= IDLE;
    end else begin
        cstate <= nstate;
    end
end

// 指令状态机状态转移
always @(*) begin
    case (cstate)
        IDLE:begin
            if (IDLE_CLASSIFICATION)begin
                nstate = INSTRUCTION_MODE;
            end else begin
                nstate = cstate;
            end
        end 
        INSTRUCTION_MODE:begin
            if (INSTR_DEAL)begin
                nstate = INSTRUCTION_DEAL;
            end else if (INSTR_NEED_DATA)begin
                nstate = INSTRUCTION_MODE_DATA;
            end else begin
                nstate = IDLE;
            end
        end
        INSTRUCTION_DEAL: begin
            nstate = OVER;
        end 
        INSTRUCTION_MODE_DATA: begin
            nstate = OVER;
        end
        OVER: begin
            nstate = IDLE;
        end
        default: begin
            nstate = IDLE;
        end 
    endcase
end

endmodule