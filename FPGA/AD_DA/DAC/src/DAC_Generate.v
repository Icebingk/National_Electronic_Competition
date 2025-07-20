/*==============================================
* Function Name  : DAC_Generate.v
* Description    : 在默认情况下：用于生成正弦波，通过LUT实现，并且进行了同步时钟域,频率为输入的频率/16个点数
*                  取消默认情况下：直接输出输入的DAC数据，使用异步FIFO进行跨时钟域传输
* input port     : rst_n(复位信号)，dac_clk(DAC时钟)，
*                  default_mode(DAC模式控制)，
*                  dac_data_in_valid(DAC数据输入有效信号)，
*                  dac_data_in(DAC输入数据)
* output port    : dac_out(DAC输出数据)
* Author         : ADBD
//==============================================*/
module DAC_Generate (
    input   wire         sys_clk,               // 系统时钟
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

// 异步FIFO信号
wire fifo_wr_en;  // 添加缺失的声明
wire [13:0] fifo_dout;
wire fifo_empty;
wire fifo_full;
reg fifo_rd_en;

// 同步default_mode到DAC时钟域
reg default_mode_meta, default_mode_sync;

// 修复：FIFO写使能应该在系统时钟域判断default_mode
assign fifo_wr_en = dac_data_in_valid && !default_mode && !fifo_full;

// 同步default_mode信号到DAC时钟域
always @(posedge dac_clk or negedge rst_n) begin
    if (!rst_n) begin
        default_mode_meta <= 1'b1;
        default_mode_sync <= 1'b1;
    end else begin
        default_mode_meta <= default_mode;
        default_mode_sync <= default_mode_meta;
    end
end

// 在DAC时钟域递增地址
always @(posedge dac_clk or negedge rst_n) begin
    if (!rst_n) begin
        phase_addr <= {sin_rom_add{1'b0}};
    end else if (default_mode_sync) begin
        if (phase_addr == sin_rom_max)
            phase_addr <= {sin_rom_add{1'b0}};
        else
            phase_addr <= phase_addr + 1'b1;
    end else begin
        phase_addr <= {sin_rom_add{1'b0}};
    end
end

// FIFO读使能控制
always @(posedge dac_clk or negedge rst_n) begin
    if (!rst_n) begin
        fifo_rd_en <= 1'b0;
    end else begin
        fifo_rd_en <= !fifo_empty && !default_mode_sync;
    end
end

// 控制输出，在DAC时钟域
always @(posedge dac_clk or negedge rst_n) begin
    if (!rst_n) begin
        dac_out <= 14'd0;
    end else if (default_mode_sync) begin
        dac_out <= dac_out_sin;
    end else if (fifo_rd_en) begin  // 使用fifo_rd_en而不是!fifo_empty
        dac_out <= fifo_dout;
    end else begin
        dac_out <= dac_out;
    end
end

// 异步FIFO实例化
fifo_generator_1  fifo_generator_1_inst (
    .rst(!rst_n),

    .wr_clk(sys_clk),
    .wr_en(fifo_wr_en),
    .din(dac_data_in),
    .full(fifo_full),
    
    .rd_clk(dac_clk),
    .rd_en(fifo_rd_en),
    .dout(fifo_dout),
    .empty(fifo_empty)
);

// ROM实例化，使用DAC时钟
sin_rom sin_rom_inst (
    .addra(phase_addr),
    .clka(dac_clk),
    .douta(dac_out_sin)
);

endmodule