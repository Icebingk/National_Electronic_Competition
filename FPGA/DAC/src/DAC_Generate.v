module DAC_Generate (
    input   wire         sys_clk,
    input   wire         rst_n,
    input   wire         dac_clk,
    output  wire [13:0]  dac_out
);

reg [11:0] add_in;
reg        write_en;
wire       full;

wire [11:0] phase_addr1;
wire         read_en;
wire        empty;

always@(posedge sys_clk or negedge rst_n)begin
    if (!rst_n)begin
        add_in <= 12'd0;
        write_en <= 1'b0;
    end else begin
        if (!full)begin
            write_en <= 1'b1; // 写使能
            if (add_in < 12'd4095) begin
                add_in <= add_in + 1'b1;
            end else begin
                add_in <= 12'd0; // 重置地址
            end
        end else begin
            write_en <= 1'b0; // FIFO满时停止写入
            add_in <= add_in; // 保持当前地址
        end
    end
end

assign read_en = !empty; // 读取使能信号为非空时有效

sin_rom sin_rom_inst (
    .addra(phase_addr1),
    .clka(dac_clk),
    .douta(dac_out)        // 直接连接14位输出
);

fifo_generator_0 fifo_generator_0_inst (
    .rst(!rst_n),           // 复位信号

    .wr_clk(sys_clk),       // 写时钟
    .din(add_in),           // 输入数据
    .wr_en(write_en),       // 写使能
    .full(full),            // FIFO满标志
    
    .rd_clk(dac_clk),       // 读时钟
    .rd_en(read_en),        // 读使能
    .dout(phase_addr1),     // 输出数据
    .empty(empty)           // FIFO空标志
);

endmodule