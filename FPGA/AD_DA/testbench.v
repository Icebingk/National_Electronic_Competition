`timescale 1ns/1ns
module testbench;

  // Parameters
  //Ports
  reg  clk_in = 0;
  reg  rst_n = 0;
  wire  clk_adc;
  reg [11:0] adc_data = 12'd2048; // 初始ADC数据
  reg  OTR = 0;
  wire  clk_dac;
  wire [13:0] dac_data;

initial begin
    forever begin
        #10 clk_in = ~clk_in;  // 10ns周期的时钟
    end
end

initial begin
    #100;rst_n = 1;
end

  top  top_inst (
    .clk_in(clk_in),
    .rst_n(rst_n),
    .clk_adc(clk_adc),
    .adc_data(adc_data),
    .OTR(OTR),
    .clk_dac(clk_dac),
    .dac_data(dac_data)
  );

//always #5  clk = ! clk ;

endmodule