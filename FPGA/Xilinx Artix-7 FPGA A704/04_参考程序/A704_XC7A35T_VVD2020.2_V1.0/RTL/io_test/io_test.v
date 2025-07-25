
module io_test
   (
      //--
      input                                  rst_n,
      input                                  clk,
      output reg                             io_sig
   );
reg[27:0]cnt;
always @ (posedge clk or negedge rst_n)begin
   if(!rst_n)
      cnt <= 28'd0;
   else if(cnt == 28'd50000000) //--50Mhz 1s ÖÓÑ­»·¼ÆÊı
      cnt <= 28'b0;
   else
      cnt <= cnt + 1'b1;
end
reg io_test_r;
always @ (posedge clk or negedge rst_n)begin
   if(!rst_n)
      io_test_r <= 1'b0;
   else if(cnt == 28'd50000000)
      io_test_r <= ~io_test_r;
end
always @ (posedge clk )begin
    io_sig <= io_test_r;
end
endmodule
