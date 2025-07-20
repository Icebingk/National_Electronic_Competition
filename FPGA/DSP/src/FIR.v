module FIR #(
    parameter DATA_WIDTH = 12,      // 输入数据位宽
    parameter COEFF_WIDTH = 32,     // 系数量化位宽
    parameter TAPS = 12,            // 滤波器抽头数
    parameter OUTPUT_WIDTH = DATA_WIDTH + COEFF_WIDTH,
    parameter MULT_LATENCY = 3      // 乘法器IP核的延迟周期(根据IP核配置调整)
)(
    input  wire                             sys_clk,
    input  wire                             rst_n,
    input  wire                             enable,       // 模块使能信号
    input  wire                             data_valid,
    input  wire signed [DATA_WIDTH-1:0]     data_in,
    output reg                              coeff_load_over,// 系数加载完成标志
    output reg                              data_ready,
    output reg signed [13:0]                data_out
);
localparam COEFF_ADDR_WIDTH = $clog2(TAPS); // 系数RAM地址宽度
localparam Scale_factor = 44; // 平衡整数和小数精度

// 系数寄存器组
reg signed [COEFF_WIDTH-1:0] coeff_reg [0:TAPS-1];// 系数寄存器
reg [7:0] coeff_load_cnt; // 系数加载计数器
// 系数RAM接口信号
wire signed [COEFF_WIDTH-1:0] ram_coeff_data;
reg [COEFF_ADDR_WIDTH-1:0] ram_coeff_addr;

// 数据移位寄存器
reg signed [DATA_WIDTH-1:0] shift_reg [0:TAPS-1];

// 乘法器IP核输入使能信号
reg [TAPS-1:0] mult_ce;
// 乘法器IP核输出
wire signed [OUTPUT_WIDTH-1:0] mult_result [0:TAPS-1];

// 累加器流水线
reg signed [OUTPUT_WIDTH-1:0] acc_pipe [0:TAPS-1];
// 有效信号流水线 - 考虑乘法器延迟
reg [TAPS+MULT_LATENCY:0] valid_pipe;

// 系数加载状态机 - 保持不变
genvar l;
generate
    for (l = 0; l < TAPS; l = l + 1) begin : coeff_load_gen
        always @(posedge sys_clk or negedge rst_n) begin
            if (!rst_n) begin
                coeff_reg[l] <= 0;
            end else if (!coeff_load_over) begin
                if (l == coeff_load_cnt) begin
                    coeff_reg[l] <= ram_coeff_data; 
                end
            end
        end
    end
endgenerate

// 系数加载辅助计数 - 保持不变
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

// 数据移位寄存器逻辑 - 保持不变
genvar i;
generate
    for (i = 0; i < TAPS; i = i + 1) begin : shift_reg_gen
        always @(posedge sys_clk or negedge rst_n) begin
            if (!rst_n) begin
                shift_reg[i] <= 0;
            end else if (enable) begin
                if (data_valid)begin
                    if (i == 0) begin
                        shift_reg[i] <= data_in; 
                    end else begin
                        shift_reg[i] <= shift_reg[i-1]; 
                    end
                end else begin
                    shift_reg[i] <= shift_reg[i];  // 保持原值
                end
            end else begin
                shift_reg[i] <= 0;  // enable为低时清零移位寄存器
            end
        end
    end
endgenerate

// 乘法器使能控制
genvar m;
generate
    for (m = 0; m < TAPS; m = m + 1) begin : mult_ce_gen
        always @(posedge sys_clk or negedge rst_n) begin
            if (!rst_n) begin
                mult_ce[m] <= 0;
            end else if (enable) begin
                mult_ce[m] <= data_valid;  // 当数据有效时使能乘法器
            end else begin
                mult_ce[m] <= 0;
            end
        end
    end
endgenerate

// 乘法器IP核实例化
genvar n;
generate
    for (n = 0; n < TAPS; n = n + 1) begin : mult_gen
        mult_gen_0 mult_gen_inst (
            .CLK(sys_clk),
            .A(shift_reg[n]),      // 连接数据输入
            .B(coeff_reg[n]),      // 连接系数输入
            .P(mult_result[n]),    // 连接乘法结果输出
            .CE(mult_ce[n])        // 连接使能信号
        );
    end
endgenerate

// 累加流水线 - 考虑乘法器延迟
genvar k;
generate
    for (k = 0; k < TAPS; k = k + 1) begin : acc_pipe_gen
        always @(posedge sys_clk or negedge rst_n) begin
            if (!rst_n) begin
                acc_pipe[k] <= 0;
            end else if (enable) begin
                // 使用有效信号流水线控制累加，考虑乘法器延迟
                if (valid_pipe[k+MULT_LATENCY]) begin
                    if (k == 0) begin
                        acc_pipe[k] <= mult_result[k];
                    end else begin
                        acc_pipe[k] <= acc_pipe[k-1] + mult_result[k];
                    end
                end else begin
                    acc_pipe[k] <= acc_pipe[k];  // 保持原值
                end
            end else begin
                acc_pipe[k] <= 0;  // enable为低时清零累加流水线
            end
        end
    end
endgenerate

// 有效信号流水线 - 与原代码行为一致，但考虑乘法器延迟
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)
        valid_pipe <= 0;
    else if (enable) begin
        if (data_valid) begin
            valid_pipe <= {valid_pipe[TAPS+MULT_LATENCY-1:0], data_valid};
        end else begin
            valid_pipe <= valid_pipe;  // 保持与原代码相同的行为
        end
    end else begin
        valid_pipe <= 0;  // enable为低时清零valid_pipe
    end
end

// 输出逻辑 - 考虑乘法器延迟
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 0;
        data_ready <= 0;
    end else if (enable) begin
        data_out <= acc_pipe[TAPS-1][Scale_factor-1:Scale_factor-14];
        data_ready <= valid_pipe[TAPS+MULT_LATENCY];  // 调整为考虑乘法器延迟
    end else begin
        data_out <= 0;      // enable为低时输出清零
        data_ready <= 0;    // enable为低时ready清零
    end
end

// 系数ROM实例
coeffs_rom coeffs_rom_inst (
    .clka(sys_clk),
    .addra(ram_coeff_addr),
    .douta(ram_coeff_data)
);

endmodule