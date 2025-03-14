`timescale  1ns/1ps
module SPI_slave_testbench;

reg             clk = 0;
reg             rst_n = 0;
reg [7:0]       data_in = 8'HF5;//1111_0101
reg             data_in_vld = 'b1;
wire[7:0]       data_out;
wire            data_out_vld;
reg             nCS = 1;
reg             MOSI = 0;
wire            MISO;
reg             CPOL = 1;
reg             CPHA = 1;
reg             DCLK;

initial begin
    forever #5 clk = ~clk;
end

initial begin
    DCLK = CPOL;
    #20 rst_n = 1; 
    #100 nCS = 0;
    #3600 nCS = 1; 
end

initial begin
    forever #200 DCLK = ~DCLK;
end

initial begin
    forever #630 MOSI = ~MOSI;
end

SPI_slave  SPI_slave_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_in_vld(data_in_vld),
    .data_out(data_out),
    .data_out_vld(data_out_vld),
    .nCS(nCS),
    .DCLK(DCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .CPOL(CPOL),
    .CPHA(CPHA)
  );

endmodule