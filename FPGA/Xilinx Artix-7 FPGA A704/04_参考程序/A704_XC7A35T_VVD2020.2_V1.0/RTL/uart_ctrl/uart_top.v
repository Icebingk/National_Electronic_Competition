`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:25:31 02/27/2016 
// Design Name: 
// Module Name:    uart_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module uart_top(
      //--
      input                               rst_n                   ,
      input                               clk                     ,
      //***********************************************************
      //--DDR
      //***********************************************************
      input                               init_calib_complete     ,
      input                               tg_compare_error        ,
      input         [ 47: 0]              w_code_rate             ,
      input         [ 47: 0]              r_code_rate             ,
      //***********************************************************
      //--Temp
      //*********************************************************** 
      input         [11:0]                device_temp             ,   
      //***********************************************************
      //--LED 
      //***********************************************************
      input         [ 1 : 0]              led                     ,
      //***********************************************************
      //--KYE 
      //***********************************************************
      input                               key                     ,   
      //***********************************************************
      //--UART Interface
      //***********************************************************
      input                               uart_rxd                ,
      output                              uart_txd
    );
wire[7:0]char_fifo_dout;
    
uart_state uart_state (
    .rst_n                 (rst_n               ), 
    .clk                   (clk                 ), 
    .init_calib_complete   (init_calib_complete ), 
    .tg_compare_error      (tg_compare_error    ), 
    .w_code_rate           (w_code_rate         ), 
    .r_code_rate           (r_code_rate         ), 
    //***********************************************************
    //--Temp
    //*********************************************************** 
    .device_temp           (device_temp         ),
    .led                   (led                 ), 
    .key                   (key                 ),
    .char_fifo_empty       (char_fifo_empty     ), 
    .char_fifo_dout        (char_fifo_dout      ), 
    .char_fifo_rd_en       (char_fifo_rd_en     )
    );
reset_bridge reset_bridge_clk_tx (
    .clk                   (clk                 ),
    .rst_n                 (rst_n               ),
    .rst_dst               (rst_clk_tx          )
  );

uart_tx uart_tx (
    .clk_tx                (clk                 ),
    .rst_clk_tx            (rst_clk_tx          ),
    .char_fifo_empty       (char_fifo_empty     ), 
    .char_fifo_dout        (char_fifo_dout      ), 
    .char_fifo_rd_en       (char_fifo_rd_en     ), 
    .txd_tx                (uart_txd            )
    );



endmodule
