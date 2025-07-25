

module  rst_ctrl
   (
    input                               sys_clk                 ,   
    input                               sys_rst_n               ,   
    //***********************************************************
    //Clock Locked
    //***********************************************************
    input     [1:0]                     clk_locked              ,
    //***********************************************************
    //Reset Out
    //***********************************************************        
    output                              rst_n
   );
//*******************************************************************
//--
//*******************************************************************   
reg [27:0]                      rst_cnt                             ;   
reg                             rst_n_r                             ;   
reg                             rst_n_temp                          ;   

//*******************************************************************
//--Clock Locked Gen 1.0S Reset
//*******************************************************************
always @ (posedge sys_clk or negedge sys_rst_n)begin
   if(!sys_rst_n)
      rst_cnt  <= 28'd0;
    else if(clk_locked==2'b11)begin
        if(rst_cnt<=28'd50000000)
            rst_cnt  <= rst_cnt + 1'b1;
        else
            rst_cnt  <= rst_cnt;
        end
   else
      rst_cnt  <= 28'd0;
end

//*******************************************************************
//--1.0S Time
//*******************************************************************
always @ (posedge sys_clk or negedge sys_rst_n)begin
   if(!sys_rst_n)
      rst_n_r  <= 1'b0;
   else if(rst_cnt<=28'd50000000)
      rst_n_r  <= 1'b0;
   else
      rst_n_r  <= 1'b1;
end
always @ (posedge sys_clk or negedge sys_rst_n)begin
   if(!sys_rst_n)
      rst_n_temp  <= 1'b0;
   else
      rst_n_temp  <= rst_n_r;
end

BUFGCE BUFGCE_inst (
      .O        (rst_n              ),   // 1-bit output: Clock output
      .CE       (1'b1               ),   // 1-bit input: Clock enable input for I0
      .I        (rst_n_temp         )    // 1-bit input: Primary clock
   );

endmodule 


