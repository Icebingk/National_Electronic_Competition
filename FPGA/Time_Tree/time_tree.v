/*==============================================
* Function Name  : time_tree.v
* Description    : 该模块用于时间树的实现，主要用于时钟分频和倍频
*                  通过分频和倍频实现不同频率的时钟输出，提供给各个模块使用。
*                  该模块可以根据需要进行扩展，支持多种时钟频率的输出。
* input port     : 
* output port    :
* Author         : ADBD
//==============================================*/

module time_tree(
    input wire sys_clk,//系统时钟50MHz
    output wire clk_adc,
    output wire clk_dac,
    output wire clk_fir,
    output wire locked
);

// 时钟生成
clk_module clk_module_inst (
    .clk_out1(clk_adc), // ADC 60MHz
    .clk_out2(clk_dac), // DAC 100MHz(后续会改为可调的)
    .clk_out3(clk_fir), // FIR 100MHz，便于流水线设计
    .locked(locked),
    .clk_in1(sys_clk)
);

endmodule