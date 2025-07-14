/*==============================================
* Function Name  : DAC_Generate.v
* Description    : 在默认情况下：用于生成正弦波，通过LUT实现，并且进行了同步时钟域,频率为输入的频率/16个点数
*                  取消默认情况下：直接输出输入的DAC数据
* input port     : rst_n(复位信号)，dac_clk(DAC时钟)，
*                  default_mode(DAC模式控制)，
*                  dac_data_in_valid(DAC数据输入有效信号)，
*                  dac_data_in(DAC输入数据)
* output port    : dac_out(DAC输出数据)
* Author         : ADBD
//==============================================*/
module DAC_Generate (
    input   wire         rst_n,                 // 低电平复位信号
    input   wire         dac_clk,               // dac时钟
    input   wire         default_mode,          // 1：默认情况，0：取消默认情况
    input   wire         dac_data_in_valid,     // DAC数据输入有效信号
    input   wire [13:0]  dac_data_in,           // DAC输入数据
    output  reg  [13:0]  dac_out                // DAC输出数据
);

localparam sin_rom_add = 5; // 根据实际ROM地址宽度设置，5位对应32点
localparam sin_rom_max = 2**sin_rom_add - 1; // 最大地址为31
wire [13:0] dac_out_sin;
reg  [sin_rom_add-1:0] phase_addr;

// 时钟域交叉处理
reg dac_auto_disa_meta, dac_auto_disa_sync;
reg dac_data_in_valid_meta, dac_data_in_valid_sync;
reg [13:0] dac_data_in_sync, dac_data_in_meta;

// 同步控制信号到DAC时钟域
always @(posedge dac_clk or negedge rst_n) begin
    if (!rst_n) begin
        dac_auto_disa_meta <= 1'b1;
        dac_auto_disa_sync <= 1'b1;
        dac_data_in_valid_meta <= 1'b0;
        dac_data_in_valid_sync <= 1'b0;
        dac_data_in_meta <= 14'd0;
        dac_data_in_sync <= 14'd0;
    end else begin
        // 两级触发器同步，减少亚稳态
        dac_auto_disa_meta <= default_mode;
        dac_auto_disa_sync <= dac_auto_disa_meta;
        dac_data_in_valid_meta <= dac_data_in_valid;
        dac_data_in_valid_sync <= dac_data_in_valid_meta;
        dac_data_in_meta <= dac_data_in;
        dac_data_in_sync <= dac_data_in_meta;
    end
end

// 在DAC时钟域递增地址
always @(posedge dac_clk or negedge rst_n) begin
    if (!rst_n) begin
        phase_addr <= {sin_rom_add{1'b0}}; // 正确的复位语法
    end else if (!dac_auto_disa_sync) begin
        if (phase_addr == sin_rom_max)
            phase_addr <= {sin_rom_add{1'b0}}; // 正确的复位语法
        else
            phase_addr <= phase_addr + 1'b1;
    end else begin
        phase_addr <= {sin_rom_add{1'b0}}; // 正确的复位语法
    end
end

// 控制输出，同样在DAC时钟域
always @(posedge dac_clk or negedge rst_n) begin
    if (!rst_n) begin
        dac_out <= 14'd0;
    end else if (!dac_auto_disa_sync) begin
        dac_out <= dac_out_sin;
    end else if (dac_data_in_valid_sync) begin
        dac_out <= dac_data_in_sync;
    end else begin
        dac_out <= dac_out;
    end
end

// ROM实例化，使用DAC时钟
sin_rom sin_rom_inst (
    .addra(phase_addr),
    .clka(dac_clk),
    .douta(dac_out_sin)
);

endmodule