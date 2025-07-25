`timescale 1ns/1ns
module top_tb;

  // Parameters

  //Ports
  reg sys_clk = 0;
  reg rst_n = 0;
  reg rx;
  wire tx;
  
  
  initial begin
    forever begin
      #10  sys_clk = ! sys_clk ;
    end
  end

  initial begin
        #1000 rst_n = !rst_n;
  end

  top  top_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .rx(rx),
    .tx(tx)
  );


endmodule