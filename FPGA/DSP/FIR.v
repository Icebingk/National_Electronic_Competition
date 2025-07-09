module FIR #(
    parameter DATA_WIDTH = 12,      // 输入数据位宽
    parameter COEFF_WIDTH = 32,     // 系数量化位宽
    parameter TAPS = 12,            // 滤波器抽头数
    parameter OUTPUT_WIDTH = DATA_WIDTH + COEFF_WIDTH
)(
    input  wire                             sys_clk,
    input  wire                             rst_n,
    input  wire                             data_valid,
    input  wire signed [DATA_WIDTH-1:0]     data_in,
    output reg                              data_ready,
    output reg signed [OUTPUT_WIDTH-1:0]    data_out
);

localparam ADDR_WIDTH = 4; // 系数RAM地址宽度

// 系数寄存器组
reg signed [COEFF_WIDTH-1:0] coeff_reg [0:TAPS-1];
reg [7:0] coeff_load_cnt;
reg coeff_loaded;
wire enable = !coeff_loaded;// 使能信号，当系数未加载时为高

// 系数RAM接口信号
wire signed [COEFF_WIDTH-1:0] ram_coeff_data;
reg [ADDR_WIDTH-1:0] ram_coeff_addr;

// 数据移位寄存器
reg signed [DATA_WIDTH-1:0] shift_reg [0:TAPS-1];
// 乘法结果流水线
reg signed [OUTPUT_WIDTH-1:0] mult_pipe [0:TAPS-1];
// 累加器流水线
reg signed [OUTPUT_WIDTH-1:0] acc_pipe [0:TAPS-1];
// 有效信号流水线
reg [TAPS:0] valid_pipe;

integer i;
// 系数加载状态机
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        coeff_load_cnt <= 0;
        coeff_loaded <= 0;
        ram_coeff_addr <= 0;
    end else if (!coeff_loaded) begin
        coeff_reg[coeff_load_cnt] <= ram_coeff_data;
        ram_coeff_addr <= coeff_load_cnt + 1;
        if (coeff_load_cnt == TAPS-1) begin
            coeff_loaded <= 1;
        end else begin
            coeff_load_cnt <= coeff_load_cnt + 1;
        end
    end else begin
        coeff_load_cnt <= coeff_load_cnt;
        coeff_loaded <= coeff_loaded;
        ram_coeff_addr <= ram_coeff_addr;
    end
end

// 系数RAM实例（假设名为coeffs_ram）
coeffs_ram coeffs_ram_inst (
    .clka(sys_clk),
    .ena(enable),
    .addra(ram_coeff_addr),
    .douta(ram_coeff_data),
    .wea(1'b0),
    .dina({COEFF_WIDTH{1'b0}})
);

// 数据移位寄存器逻辑
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < TAPS; i = i + 1)
            shift_reg[i] <= 0;
    end else if (data_valid && coeff_loaded) begin
        shift_reg[0] <= data_in;
        for (i = 1; i < TAPS; i = i + 1)
            shift_reg[i] <= shift_reg[i-1];
    end
end

// 乘法流水线
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < TAPS; i = i + 1)
            mult_pipe[i] <= 0;
    end else if (data_valid && coeff_loaded) begin
        for (i = 0; i < TAPS; i = i + 1)
            mult_pipe[i] <= shift_reg[i] * coeff_reg[i];
    end
end

// 累加流水线
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < TAPS; i = i + 1)
            acc_pipe[i] <= 0;
    end else if (data_valid) begin
        acc_pipe[0] <= mult_pipe[0];
        for (i = 1; i < TAPS; i = i + 1)
            acc_pipe[i] <= acc_pipe[i-1] + mult_pipe[i];
    end
end

// 有效信号流水线
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)
        valid_pipe <= 0;
    else
        valid_pipe <= {valid_pipe[TAPS-1:0], data_valid};
end

// 输出
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 0;
        data_ready <= 0;
    end else begin
        data_out <= acc_pipe[TAPS-1];
        data_ready <= valid_pipe[TAPS];
    end
end

endmodule