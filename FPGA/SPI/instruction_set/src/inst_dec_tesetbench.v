`timescale 1ns/1ns
module inst_dec_tb;

  // Parameters
`include "E:/NEC/FPGA/SPI/src/top_define.v"

  //Ports
  reg  sys_clk = 0;
  reg  rst_n = 0;
  reg [`DATA_WIDTH-1:0] inst_data = 0;
  reg  inst_data_valid = 0;
  wire inst_data_ready;
  wire [`DATA_WIDTH-1:0] instr_data_out;
  wire device_enable;
  wire [`DEVICE_CONTROL_WIDTH/2-2:0] device_control;
  wire data_out_vld;
  wire  data_out_ready;

  wire  enable;
  wire  valid;
  wire  ready;
  wire  [2:0] clk_control_num;
  wire  [2:0] clk_choise;
  wire  [7:0] frq_mult_int;
  wire  [7:0] frq_mult_float;
  wire  [7:0] frq_div_int;
  wire  [7:0] frq_div_float;
  wire  [31:0] frq_phase_value;
  wire  accomplish;
  wire  ID_READ_Flag;
  wire  ADC_Trans_Flag;
  wire  default_mode;
  wire  dac_data_in_valid;
  wire  FIR_ADC_Enable;
  wire  FIR_DAC_Enable;
  wire  Freq_Phase_Enable;
  
    wire  error_sign;
    wire  clk_adc;
    wire  clk_dac;
    wire  clk_fir;
    wire  locked;

  initial begin
    forever #10 sys_clk = ~sys_clk; // 时钟周期为10ns
  end
  
  initial begin
    #100; 
    rst_n = 1; // 复位信号有效
end

initial begin
    // #200;
    // inst_data = 16'hFFAE; // 设备ID指令
    // inst_data_valid = 1; // 指令数据有效
    // #20;
    // inst_data_valid = 0; // 指令数据无效

    // #50;
    // inst_data = 16'h0002; 
    // inst_data_valid = 1; // 控制指令
    // #20;
    // inst_data_valid = 0; // 指令数据无效
    
    // #50;
    // inst_data = 16'h2400; //8.125
    // inst_data_valid = 1; // 控制指令
    // #20;
    // inst_data_valid = 0; // 指令数据无效

    // #50;
    // inst_data = 16'h0200; 
    // inst_data_valid = 1; // 控制指令
    // #20;
    // inst_data_valid = 0; // 指令数据无效

    // #20;

    // #50;
    // inst_data = 16'h0001; 
    // inst_data_valid = 1; // 控制指令
    // #20;
    // inst_data_valid = 0; // 指令数据无效

    // #50;
    // inst_data = 16'h3819; // 56.25
    // inst_data_valid = 1; // 控制指令
    // #20;
    // inst_data_valid = 0; // 指令数据无效

    // #20;

    // #50;
    // inst_data = 16'h0003; 
    // inst_data_valid = 1; // 控制指令
    // #20;
    // inst_data_valid = 0; // 指令数据无效

    // #50;
    // inst_data = 16'h0900; //9
    // inst_data_valid = 1; // 控制指令
    // #20;
    // inst_data_valid = 0; // 指令数据无效

    // #20;

    // #50;
    // inst_data = 16'h0001; 
    // inst_data_valid = 1; // 控制指令
    // #20;
    // inst_data_valid = 0; // 指令数据无效

    // #50;
    // inst_data = 16'h00B4; // 180°
    // inst_data_valid = 1; // 控制指令
    // #20;
    // inst_data_valid = 0; // 指令数据无效

    // #20;

    // #50;
    // inst_data = 16'h0003; 
    // inst_data_valid = 1; // 控制指令
    // #20;
    // inst_data_valid = 0; // 指令数据无效

    // #50;
    // inst_data = 16'h0000; 
    // inst_data_valid = 1; // 控制指令
    // #20;
    // inst_data_valid = 0; // 指令数据无效

    // #200;

    #500;
    inst_data = 16'hFFAA; // 2开
    inst_data_valid = 1; // 控制指令
    #20;
    inst_data_valid = 0; // 指令数据无效
    
    #50;
    inst_data = 16'hFFAB;// 3开
    inst_data_valid = 1; // 控制指令
    #20;
    inst_data_valid = 0; // 指令数据无效

    #50;
    inst_data = 16'hFFA2; // 2关
    inst_data_valid = 1; // 控制指令
    #30;
    inst_data_valid = 0; // 指令数据无效    
    
end

  inst_dec  inst_dec_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .inst_data(inst_data),
    .inst_data_valid(inst_data_valid),
    .inst_data_ready(inst_data_ready),
    .instr_data_out(instr_data_out),
    .device_enable(device_enable),
    .device_control(device_control),
    .data_out_vld(data_out_vld),
    .data_out_ready(data_out_ready)
  );

inst_data_deal  inst_data_deal_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),

    .instr_data_out(instr_data_out),
    .device_enable(device_enable),
    .device_control(device_control),
    .data_out_vld(data_out_vld),
    .data_out_ready(data_out_ready),
    
    .enable(enable),
    .valid(valid),
    .ready(ready),
    .clk_control_num(clk_control_num),
    .clk_choise(clk_choise),
    .frq_mult_int(frq_mult_int),
    .frq_mult_float(frq_mult_float),
    .frq_div_int(frq_div_int),
    .frq_div_float(frq_div_float),
    .frq_phase_value(frq_phase_value),
    .accomplish(accomplish),

    .ID_READ_Flag(ID_READ_Flag),

    .ADC_Trans_Flag(ADC_Trans_Flag),
    
    .default_mode(default_mode),
    .dac_data_in_valid(dac_data_in_valid),
    
    .FIR_ADC_Enable(FIR_ADC_Enable),
    
    .FIR_DAC_Enable(FIR_DAC_Enable),
    
    .Freq_Phase_Enable(Freq_Phase_Enable)
  );

  time_tree_dy  time_tree_dy_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .enable(enable),
    .valid(valid),
    .ready(ready),
    .clk_control_num(clk_control_num),
    .clk_choise(clk_choise),
    .frq_mult_int(frq_mult_int),
    .frq_mult_float(frq_mult_float),
    .frq_div_int(frq_div_int),
    .frq_div_float(frq_div_float),
    .frq_phase_value(frq_phase_value),
    .accomplish(accomplish),
    .error_sign(error_sign),
    .clk_adc(clk_adc),
    .clk_dac(clk_dac),
    .clk_fir(clk_fir),
    .locked(locked)
  );

endmodule