`timescale  1ns/1ps
module SPI_slave_testbench;

reg             clk = 0;
reg             rst = 1;
reg [7:0]       data_in = 8'HF5;//1111_0101
reg             data_in_vld = 'b1;
wire[7:0]       data_out;
wire            data_out_vld;
reg             nCS = 1;
reg             MOSI = 0;
wire            MISO;
reg             CPOL = 0;
reg             CPHA = 0;
reg             DCLK;
wire [7:0] seg_number;
wire [7:0] seg_choice;
wire [2:0] mode;
initial begin
    forever #5 clk = ~clk;
end

initial begin
    DCLK = CPOL;
    #20 rst = 0; 
    #100 nCS = 0;
    #51000 nCS = 1;

end

initial begin
    #1000;
    repeat(160) begin
        #300 DCLK = ~DCLK;
    end 
end

initial begin
    forever #530 MOSI = ~MOSI;
end

  SPI_control  SPI_control_inst (
    .clk(clk),
    .rst(rst),
    .seg_number(seg_number),
    .seg_choice(seg_choice),
    .CPHA(CPHA),
    .CPOL(CPOL),
    .DCLK(DCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .nCS(nCS),
    .mode(mode)
  );
endmodule