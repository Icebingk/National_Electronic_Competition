/*==============================================
* Function Name  : top.v
* Description    : 该模块是为了验证动态输出正弦波的顶层模块
* input port     : 详细接口见下方注释
* output port    : 详细接口见下方注释
* Author         : ADBD
//==============================================*/
module top(
    input wire sys_clk,          // 系统时钟
    input wire rst_n,            // 复位信号，低有效

    output wire clk_adc,         // ADC采样时钟
    output wire clk_dac,         // DAC输出时钟
    output wire clk_fir,         // FIR滤波器时钟
    output wire locked,         // 时钟锁定信号

    output wire[13:0] dac_out,  // DAC输出数据
    output reg light
);

wire error_sign; // 错误信号

wire [13:0] dac_data_in_w = 14'd0; // DAC输入数据
wire        dac_data_in_valid_w = 0;

reg         enable;// 一个时钟周期也可以
reg         valid = 1;
wire        ready;

reg [2:0]   clk_cnt;
wire[2:0]   clk_choise;


// 写固定值验证模块
reg [7:0]   all_mult_int = 8'd36;
reg [7:0]   all_mult_float = 8'd0;
reg [7:0]   all_div_int  = 8'd2;
reg [7:0]   clk1_div_int = 8'd56;
reg [7:0]   clk1_div_flt = 8'd250;
reg [7:0]   clk2_div_int = 8'd15;
reg [7:0]   clk3_div_int = 8'd15;
reg [31:0]  clk1_phase   = 32'd0;
reg [31:0]  clk2_phase   = 32'd180;
reg [31:0]  clk3_phase   = 32'd0;

reg [7:0]   frq_div_int;
reg [7:0]   frq_div_float;
reg [31:0]  frq_phase_value;
wire        accomplish;

reg flag;
always@(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        light <= 1'd0; // 初始化DAC输出数据
    end else if (error_sign) begin
        light <= 1'b1; // 更新DAC输出数据
    end else begin
        light <= light; // 保持当前输出数据
    end
end

always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
        flag <= 1'b0;
    end else if (accomplish) begin
        flag <= 1'b1;
    end else begin
        flag <= flag;
    end
end

// 只写一次
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        enable <= 1'b0;
    end else if (flag) begin
        enable <= 1'b0; // 当flag为1时，禁用模块
    end else if (locked) begin
        enable <= 1'b1; // 当PLL锁定后，启用模块
    end else begin
        enable <= enable; // 保持当前状态
    end
end


always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
        clk_cnt <= 3'd0;
    end else if (ready)begin
        clk_cnt <= clk_cnt + 3'd1; // 每次ready信号有效时，切换时钟选择
    end else if (accomplish)begin
        clk_cnt <= 3'd0; // 写寄存器完成后，重置时钟选择
    end else begin
        clk_cnt <= clk_cnt; // 保持当前选择
    end
end

assign clk_choise = (clk_cnt <= 3'd3) ? clk_cnt : clk_cnt - 3'd3; // 根据计数器值选择时

always @(*) begin
    if (!rst_n)begin
        frq_div_int     = 8'd0; // 初始化频率相关寄存器
        frq_div_float   = 8'd0; // 初始化频率相关寄存器
        frq_phase_value = 32'd0; // 初始化频率相关寄存器
    end else begin
        case (clk_cnt)
            3'd0: begin
                frq_div_int     =  all_div_int; // 
                frq_div_float   =  8'd0; //
                frq_phase_value =  32'd0; //
            end
            3'd1:begin
                frq_div_int     =  clk1_div_int; // 
                frq_div_float   =  clk1_div_flt; 
                frq_phase_value =  32'd0;
            end
            3'd2:begin
                frq_div_int     =  clk2_div_int; // 
                frq_div_float   =  8'd0; //
                frq_phase_value =  32'd0; //
            end
            3'd3:begin
                frq_div_int     =  clk3_div_int; // 
                frq_div_float   =  8'd0; //
                frq_phase_value =  32'd0; //
            end
            3'd4:begin
                frq_div_int     = 8'd0; // 
                frq_div_float   =  8'd0; //
                frq_phase_value =  clk1_phase;
            end
            3'd5:begin
                frq_div_int     = 8'd0; // 
                frq_div_float   =  8'd0; //
                frq_phase_value =  clk2_phase;
            end
            3'd6:begin
                frq_div_int     = 8'd0; // 
                frq_div_float   =  8'd0; //
                frq_phase_value =  clk3_phase;
            end
            default: begin
                frq_div_int     =  8'd0; // 初始化频率相关寄存器
                frq_div_float   =  8'd0; // 初始化频率相关寄存器
                frq_phase_value =  32'd0; // 初始化频率相关寄存器
            end
        endcase
    end
end



time_tree_dy  time_tree_dy_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .enable(enable),
    .valid(valid),
    .ready(ready),
    .clk_control_num(3'd3),
    .clk_choise(clk_choise),
    .frq_mult_int(all_mult_int),
    .frq_mult_float(all_mult_float),
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

DAC_Generate  DAC_Generate_inst (
    .rst_n(rst_n),
    .dac_clk(clk_dac),
    .default_mode(1'b0),
    .dac_data_in_valid(dac_data_in_valid_w),
    .dac_data_in(dac_data_in_w),
    .dac_out(dac_out)
);

endmodule