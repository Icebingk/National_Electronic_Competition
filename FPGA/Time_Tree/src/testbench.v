`timescale 1ps/1ps
module testbench;

reg sys_clk = 0;
reg rst_n = 0;

wire clk_adc;
wire clk_dac;
wire clk_fir;
wire locked;
wire [13:0] dac_out;
wire light;

initial begin
    forever begin
        #10 sys_clk = ~sys_clk; // 10ns周期的时钟
    end
end

initial begin
    #100; rst_n = 1; // 复位信号
end

top  top_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .clk_adc(clk_adc),
    .clk_dac(clk_dac),
    .clk_fir(clk_fir),
    .locked(locked),
    .dac_out(dac_out),
    .light(light)
  );

endmodule