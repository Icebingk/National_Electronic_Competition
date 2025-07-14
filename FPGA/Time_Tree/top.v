module top(
    input sys_clk,          // 系统时钟
    input rst_n,            // 复位信号，低有效
    input valid,            // 输入有效信号

    output clk_adc,         // ADC采样时钟
    output clk_dac,         // DAC输出时钟
    output clk_fir,         // FIR滤波器时钟
    output locked,         // 时钟锁定信号

    output [13:0] dac_out,  // DAC输出数据
    output ligtht           

);
assign ligtht = 1'b1; // 测试用的输出信号

wire [3:0] key_edge_pos; // 按键上升沿信号
wire [3:0] key_edge_neg; // 按键下降沿信号
wire error_sign; // 错误信号

wire [2:0] clk_choise = 3'd0;  // 时钟选择信号
wire [7:0] frq_num_int = 8'd28;  // 频率分频或者倍频数，整数部分
wire [7:0] frq_num_float = 8'd125; // 频率分频或者倍频数，小数部分

wire [13:0] dac_data_in_w = 14'd0; // DAC输入数据
wire        dac_data_in_valid_w = 0;

key_edge  key_edge_inst (
    .clk(sys_clk),
    .key_in({1'd0,rst_n,valid}),
    .key_edge_pos(key_edge_pos),
    .key_edge_neg(key_edge_neg)
  );

time_tree_dy  time_tree_dy_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .enable(key_edge_pos[0]),
    .clk_choise(clk_choise),
    .frq_num_int(frq_num_int),
    .frq_num_float(frq_num_float),
    .error_sign(error_sign),
    .clk_adc(clk_adc),
    .clk_dac(clk_dac),
    .clk_fir(clk_fir),
    .locked(locked)
);

DAC_Generate  DAC_Generate_inst (
    .rst_n(rst_n),
    .dac_clk(clk_dac),
    .default_mode(0),
    .dac_data_in_valid(dac_data_in_valid_w),
    .dac_data_in(dac_data_in_w),
    .dac_out(dac_out)
);

endmodule