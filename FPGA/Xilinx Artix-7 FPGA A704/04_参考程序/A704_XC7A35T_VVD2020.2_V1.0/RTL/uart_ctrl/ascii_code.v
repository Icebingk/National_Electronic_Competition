`timescale 1ns / 1ps

module ascii_code
    #
     (
      parameter         DATA_IN_WIDTH         =     48,
      parameter         DATA_OUT_WIDTH        =     DATA_IN_WIDTH*2,
      parameter         NUM                   =     DATA_IN_WIDTH/4
     )
     (
      //--
      input                               rst_n                   ,   
      input                               clk                     ,   
      //***********************************************************
      //--UART Interface
      //***********************************************************
      input                               d_in_en                 ,   
      input       [DATA_IN_WIDTH-1 :0]    d_in                    ,   
      output   reg[DATA_OUT_WIDTH-1:0]    d_out
     );
genvar i;
   generate
      for (i=0; i < NUM; i=i+1) 
      begin: REG
         always @ (posedge clk or negedge rst_n)begin
            if(!rst_n)
               d_out[(i+1)*8-1:i*8] <= 8'b0;
            else if(d_in_en==1'b1)case(d_in[(i+1)*4-1:i*4])
               4'h0     :   d_out[(i+1)*8-1:i*8] <= 8'h30;
               4'h1     :   d_out[(i+1)*8-1:i*8] <= 8'h31;
               4'h2     :   d_out[(i+1)*8-1:i*8] <= 8'h32;
               4'h3     :   d_out[(i+1)*8-1:i*8] <= 8'h33;
               4'h4     :   d_out[(i+1)*8-1:i*8] <= 8'h34;
               4'h5     :   d_out[(i+1)*8-1:i*8] <= 8'h35;
               4'h6     :   d_out[(i+1)*8-1:i*8] <= 8'h36;
               4'h7     :   d_out[(i+1)*8-1:i*8] <= 8'h37;
               4'h8     :   d_out[(i+1)*8-1:i*8] <= 8'h38;
               4'h9     :   d_out[(i+1)*8-1:i*8] <= 8'h39;
               4'hA     :   d_out[(i+1)*8-1:i*8] <= 8'h41;
               4'hB     :   d_out[(i+1)*8-1:i*8] <= 8'h42;
               4'hC     :   d_out[(i+1)*8-1:i*8] <= 8'h43;
               4'hD     :   d_out[(i+1)*8-1:i*8] <= 8'h44;
               4'hE     :   d_out[(i+1)*8-1:i*8] <= 8'h45;
               4'hF     :   d_out[(i+1)*8-1:i*8] <= 8'h46;
               default  :   d_out[(i+1)*8-1:i*8] <= 8'h20;
            endcase
         end
      end
   endgenerate
endmodule
