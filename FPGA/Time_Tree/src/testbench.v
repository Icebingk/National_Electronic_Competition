`timescale 1ns/1ps
module PLL_Control_tb;

  // Parameters

  //Ports
  reg  sys_clk = 0;
  reg  rst_n = 0;
  wire  clk_out1;
  wire [7:0] frq;
  reg  frq_search_over = 1;
  reg  clc_accompish = 1;
  wire  locked;

initial begin
    #100; rst_n = 1;
end

initial begin
    #2000; clc_accompish = 0;

    #10000; clc_accompish = 1;
    #20; clc_accompish = 0;
end

initial begin
    forever begin
        #10; sys_clk = ~sys_clk;
    end
end

MMCM_Control  MMCM_Control_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .clk_out1(clk_out1),
    .frq(frq),
    .frq_search_over(frq_search_over),
    .clc_accompish(clc_accompish),
    .locked(locked)
  );

//always #5  clk = ! clk ;

endmodule