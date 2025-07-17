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
    output reg signed [13:0]    data_out
);
localparam COEFF_ADDR_WIDTH = $clog2(TAPS); // 系数RAM地址宽度
localparam Scale_factor = 25; // 平衡整数和小数精度

// 系数寄存器组
reg signed [COEFF_WIDTH-1:0] coeff_reg [0:TAPS-1];// 系数寄存器
reg [7:0] coeff_load_cnt; // 系数加载计数器
reg       coeff_load_over; // 系数加载完成标志
// 系数RAM接口信号
wire signed [COEFF_WIDTH-1:0] ram_coeff_data;
reg [COEFF_ADDR_WIDTH-1:0] ram_coeff_addr;

// 数据移位寄存器
reg signed [DATA_WIDTH-1:0] shift_reg [0:TAPS-1];
// 乘法结果流水线
reg signed [OUTPUT_WIDTH-1:0] mult_pipe [0:TAPS-1];
// 累加器流水线
reg signed [OUTPUT_WIDTH-1:0] acc_pipe [0:TAPS-1];
// 有效信号流水线
reg [TAPS:0] valid_pipe;

// 系数加载状态机
genvar l;
generate
    for (l = 0; l < TAPS; l = l + 1) begin : coeff_load_gen
        always @(posedge sys_clk or negedge rst_n) begin
            if (!rst_n) begin
                coeff_reg[l] <= 0;
            end else if (!coeff_load_over) begin
                if (l == coeff_load_cnt) begin
                    coeff_reg[l] <= ram_coeff_data; // 从RAM加载系数
                end
            end
        end
    end
endgenerate

always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        coeff_load_cnt <= 0;
        coeff_load_over <= 0;
        ram_coeff_addr <= 0;
    end else if (!coeff_load_over) begin
        ram_coeff_addr <= coeff_load_cnt + 1;
        if (coeff_load_cnt == TAPS-1) begin
            coeff_load_over <= 1;
        end else begin
            coeff_load_cnt <= coeff_load_cnt + 1;
        end
    end else begin
        coeff_load_cnt <= coeff_load_cnt;
        coeff_load_over <= coeff_load_over;
        ram_coeff_addr <= ram_coeff_addr;
    end
end

// 数据移位寄存器逻辑
genvar i;
generate
    for (i = 0; i < TAPS; i = i + 1) begin : shift_reg_gen
        always @(posedge sys_clk or negedge rst_n) begin
            if (!rst_n) begin
                shift_reg[i] <= 0;
            end else if (data_valid) begin
                if (i == 0) begin
                    shift_reg[i] <= data_in; // 第一个寄存器直接接收输入数据
                end else begin
                    shift_reg[i] <= shift_reg[i-1]; // 后续寄存器从前一个寄存器获取数据
                end
            end
        end
    end
endgenerate

// 乘法流水线
genvar j;
generate
    for (j = 0; j < TAPS; j = j + 1) begin : mult_pipe_gen
        always @(posedge sys_clk or negedge rst_n) begin
            if (!rst_n) begin
                mult_pipe[j] <= 0;
            end else if (data_valid && coeff_load_over) begin
                mult_pipe[j] <= shift_reg[j] * coeff_reg[j]; // 乘法操作
            end
        end
    end
endgenerate

// 累加流水线
genvar k;
generate
    for (k = 0; k < TAPS; k = k + 1) begin : acc_pipe_gen
        always @(posedge sys_clk or negedge rst_n) begin
            if (!rst_n) begin
                acc_pipe[k] <= 0;
            end else if (valid_pipe[k]) begin
                if (k == 0) begin
                    acc_pipe[k] <= mult_pipe[k]; // 第一个累加器直接接收乘法结果
                end else begin
                    acc_pipe[k] <= acc_pipe[k-1] + mult_pipe[k]; // 后续累加器从前一个累加器获取数据
                end
            end
        end
    end
endgenerate

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
        // 输出高14位，适配14位DAC
        data_out <= acc_pipe[TAPS-1][Scale_factor-1:Scale_factor-14];
        data_ready <= valid_pipe[TAPS];
    end
end

// 系数ROM实例（假设名为coeffs_ram）
coeffs_rom coeffs_rom_inst (
    .clka(sys_clk),
    .addra(ram_coeff_addr),
    .douta(ram_coeff_data)
);

endmodule