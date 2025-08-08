`timescale 1ns/1ns
module top_tb;

  // Parameters

  //Ports
  reg  sys_clk = 0;
  reg  rst_n = 0;
  reg [11:0] adc_data_in;
  wire OTR = 0;

  initial begin
    #500; rst_n = 1;
  end

  initial begin
    forever begin
        #10; sys_clk = ~sys_clk;
    end
  end

  initial begin
    forever begin
      #20; adc_data_in = $random & 12'hFFF; // Generate 12-bit random number
    end
  end

  top  top_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .adc_data_in(adc_data_in),
    .OTR(OTR)

  );

//always #5  clk = ! clk ;

endmodule