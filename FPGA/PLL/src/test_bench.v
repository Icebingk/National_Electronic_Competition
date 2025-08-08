`timescale 1ns/1ns
module ADF4351_tb;

  // Parameters

  //Ports
  reg  sys_clk = 0;
  reg  rst_n = 0;
  wire DCLK;
  wire MOSI;
  reg  MISO = 0;
  wire nCS;
  wire ce;

initial begin
    forever #5 sys_clk = ~sys_clk; // Generate clock signal
end

initial begin
    #100 rst_n = 1; // Release reset after 100 ns

end

  ADF4351  ADF4351_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .DCLK(DCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .nCS(nCS),
    .ce(ce)
  );

//always #5  clk = ! clk ;

endmodule