

module  clk_ctrl
   (
      input                               clk                     ,   
      input                               rst_n                   ,   
      //***********************************************************
      //Clock OUT
      //***********************************************************
      output                              clk_200M                ,   
      output                              clk_50M                 ,   
      output                              ddr3_clk                ,
      //***********************************************************
      //Clock Locked
      //***********************************************************
      output    [1:0]                     clk_locked                
   );
//***************************************************************
//50M-->200M
//50M-->125M
//50M-->50M
//50M-->25M
//***************************************************************   
  sys_clk U0_sys_clk
   (// Clock in ports
    .clk_in1                    (clk                        ),     // IN
    // Clock out ports
    .clk_200M                   (clk_200M                   ),     // OUT
    .clk_50M                    (clk_50M                    ),     // OUT
    // Status and control signals
    .reset                      (1'b0                       ),
    .locked                     (clka_locked                )
   );

//***************************************************************
//50M-->333M
//***************************************************************
ddr_clk U1_ddr_clk
(// Clock in ports
    .clk_in1                    (clk_50M                    ),     // IN
    // Clock out ports
    .ddr3_clk                   (ddr3_clk                   ),     // OUT
    // Status and control signals
    .reset                      (1'b0                       ),
    .locked                     (clkb_locked                )
 );
//***************************************************************
//Clock Locked
//***************************************************************
 assign  clk_locked = {clka_locked,clkb_locked};
endmodule 

