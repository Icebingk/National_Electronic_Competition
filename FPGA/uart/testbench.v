`timescale  1ns/1ps
module top_tb;

  // Parameters

  //Ports
  reg  sys_clk = 0;
  reg  rst_n = 0;
  reg  rx = 1;
  wire tx;
  wire [2:0] mode;
  reg  CPHA = 0;
  reg  CPOL = 0;
  reg  DCLK = 0;
  reg  MOSI = 0;
  wire  MISO;
  reg  nCS = 1;

initial begin
    forever begin
        sys_clk = ~sys_clk;
        #10;  // 10ns clock period
    end
end

initial begin
    rst_n = 0;
    #40;  // 20ns reset duration
    rst_n = 1;
end

initial begin
    #200;
    nCS = 0;  // Activate SPI slave
    #100_000;
    nCS = 1;
end

initial begin
    forever begin
        #500;  // 20ns clock period for DCLK
        DCLK = ~DCLK;
    end
end

initial begin
    forever begin
        #499;
        MOSI = $random % 2;  // Randomly set MOSI
    end
end

  top  top_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .rx(rx),
    .tx(tx),
    .mode(mode),
    .CPHA(CPHA),
    .CPOL(CPOL),
    .DCLK(DCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .nCS(nCS)
  );

endmodule