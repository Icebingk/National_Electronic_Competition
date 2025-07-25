`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:33:33 02/27/2016 
// Design Name: 
// Module Name:    uart_state 
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
module uart_state(
      //--
      input                               rst_n                   ,
      input                               clk                     ,
      //*************************************************
      //--DDR
      //*************************************************
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
      //--KEY 
      //***********************************************************
      input                               key                     ,   
      //***********************************************************
      //--UART
      //***********************************************************
      output     reg                      char_fifo_empty         ,   // Empty signal from char FIFO (FWFT)
      output     reg[ 7 : 0]              char_fifo_dout          ,   // Data from the char FIFO
      input                               char_fifo_rd_en             // Pop signal to the char FIFO
    );
    

wire        [12*2-1:0]          device_temp_h_r                     ;   
wire        [8*1-1:0]           device_temp_l_r                     ;   
wire        [20:0]              device_temp_mul                     ;   
wire        [8:0]               device_temp_div                     ;   
wire        [7:0]               device_temp_del                     ;   

reg                             d_in_en                             ; 
//*******************************************************************
//
//******************************************************************* 
always @ (posedge clk or negedge rst_n)begin
   if(!rst_n)
      d_in_en <= 1'b0;
   else if(time_cnt == 28'd1)
      d_in_en <= 1'b1;
   else
      d_in_en <= 1'b0;
end
//*******************************************************************
//--LED
//*******************************************************************
reg[7:0]led_r1[0:1];
always @ (posedge clk or negedge rst_n)begin
   if(!rst_n)begin
      led_r1[0] <= 8'b0;led_r1[1] <= 8'b0;
      end
   else if(led[1]==1'b1)begin
      led_r1[0] <= 8'hA1;led_r1[1] <= 8'hEE;//--¡î
      end
   else begin                     
      led_r1[0] <= 8'hA1;led_r1[1] <= 8'hEF;//--¡ï
      end
end
reg[7:0]led_r2[0:1];
always @ (posedge clk or negedge rst_n)begin
   if(!rst_n)begin
      led_r2[0] <= 8'b0;led_r2[1] <= 8'b0;
      end
   else if(led[0]==1'b1)begin
      led_r2[0] <= 8'hA1;led_r2[1] <= 8'hEE;//--¡î
      end
   else begin                     
      led_r2[0] <= 8'hA1;led_r2[1] <= 8'hEF;//--¡ï
      end
end
//*******************************************************************
//--KYE
//*******************************************************************
reg[7:0]key_r1[0:5];
always @ (posedge clk or negedge rst_n)begin
   if(!rst_n)begin
      key_r1[0] <= 8'b0;key_r1[1] <= 8'b0;
      key_r1[2] <= 8'b0;key_r1[3] <= 8'b0;
      key_r1[4] <= 8'b0;key_r1[5] <= 8'b0;
      end
   else if(key==1'b1)begin
      key_r1[0] <= 8'hB8;key_r1[1] <= 8'hDF;  //¸ß
      key_r1[2] <= 8'hB5;key_r1[3] <= 8'hE7;  //µç
      key_r1[4] <= 8'hC6;key_r1[5] <= 8'hBD;  //Æ½
      end
   else begin                     
      key_r1[0] <= 8'hB5;key_r1[1] <= 8'hCD;  //µÍ
      key_r1[2] <= 8'hB5;key_r1[3] <= 8'hE7;  //µç
      key_r1[4] <= 8'hC6;key_r1[5] <= 8'hBD;  //Æ½
      end
end
//*******************************************************************
//--Temp
//*******************************************************************
assign  device_temp_mul = device_temp * 504;
assign  device_temp_div = device_temp_mul[20:12];
assign  device_temp_del = device_temp_div - 273;
device_temp_ascii_dis device_temp_h
     (
      //--
    .rst_n                      (rst_n                      ),
    .clk                        (clk                        ),
    .d_in_en                    (d_in_en                    ),
    .d_in                       (device_temp_del            ),
    .d_out                      (device_temp_h_r            )
     );
ascii_code #
    (
    .DATA_IN_WIDTH              (4                           ),
    .DATA_OUT_WIDTH             (4*2                         )
    ) 
    device_temp_l 
    (
    .rst_n                      (rst_n                       ), 
    .clk                        (clk                         ), 
    .d_in_en                    (d_in_en                     ),
    .d_in                       ({1'b0,device_temp_mul[11:9]}), 
    .d_out                      (device_temp_l_r             )
    );
//*******************************************************************
//--DDR³õÊ¼»¯
//--³É¹¦£ºB3 C9 B9 A6 
//--Ê§°Ü£ºCA A7 B0 DC
//*******************************************************************
reg         [7:0]               ddr_init_state[0:3]                 ;
always @ (posedge clk or negedge rst_n)begin
   if(!rst_n)begin
      ddr_init_state[0] <= 8'b0;ddr_init_state[1] <= 8'b0;
      ddr_init_state[2] <= 8'b0;ddr_init_state[3] <= 8'b0;
      end
   else if(init_calib_complete==1'b1)begin
      ddr_init_state[0] <= 8'hB3;ddr_init_state[1] <= 8'hC9;//--³É
      ddr_init_state[2] <= 8'hB9;ddr_init_state[3] <= 8'hA6;//--¹¦
      end
   else begin                     
      ddr_init_state[0] <= 8'hCA;ddr_init_state[1] <= 8'hA7;//--Ê§
      ddr_init_state[2] <= 8'hB0;ddr_init_state[3] <= 8'hDC;//--°Ü
      end
end
//*******************************************************************
//--DDR×Ô¼ì
//--ÕýÈ·£ºD5 FD C8 B7 
//--´íÎó£ºB4 ED CE F3 
//*******************************************************************
reg         [7:0]               ddr_rw_state[0:3]                   ;
always @ (posedge clk or negedge rst_n)begin
   if(!rst_n)begin
      ddr_rw_state[0] <= 8'b0;ddr_rw_state[1] <= 8'b0;
      ddr_rw_state[2] <= 8'b0;ddr_rw_state[3] <= 8'b0;
      end
   else if(init_calib_complete==1'b1 && tg_compare_error==1'b0)begin
      ddr_rw_state[0] <= 8'hD5;ddr_rw_state[1] <= 8'hFD;//--Õý
      ddr_rw_state[2] <= 8'hC8;ddr_rw_state[3] <= 8'hB7;//--È·
      end
   else begin                     
      ddr_rw_state[0] <= 8'hB4;ddr_rw_state[1] <= 8'hED;//--Îó
      ddr_rw_state[2] <= 8'hCE;ddr_rw_state[3] <= 8'hF3;//--´í
      end
end

//*************************************
//--DDRÐ´ÂëÂÊ16½øÖÆ ¡ª¡ª> ×Ö·û
//*************************************
wire[48*2-1:0]w_code_rate_r;
ascii_code #
    (
    .DATA_IN_WIDTH        (48                  ),
    .DATA_OUT_WIDTH       (48*2                )
    ) 
    DDR_WR
    (
    .rst_n                (rst_n               ), 
    .clk                  (clk                 ), 
    .d_in_en              (d_in_en             ),
    .d_in                 (w_code_rate         ), 
    .d_out                (w_code_rate_r       )
    );
//*************************************
//--DDR¶ÁÂëÂÊ16½øÖÆ ¡ª¡ª> ×Ö·û
//*************************************
wire[48*2-1:0]r_code_rate_r;
ascii_code #
    (
    .DATA_IN_WIDTH        (48                  ),
    .DATA_OUT_WIDTH       (48*2                )
    ) 
    DDR_RD
    (
    .rst_n                (rst_n               ), 
    .clk                  (clk                 ), 
    .d_in_en              (d_in_en             ),
    .d_in                 (r_code_rate         ), 
    .d_out                (r_code_rate_r       )
    );
//*************************************************************************
//²½½ø²ÎÊý¶¨Òå
//*************************************************************************
localparam  I1   =   0;
localparam  I2   =   I1 + 50;
localparam  I3   =   I2 + 30;
localparam  I4   =   I3 + 30;
localparam  I5   =   I4 + 20;
localparam  I6   =   I5 + 20;
localparam  I7   =   I6 + 30;
localparam  I8   =   I7 + 30;
localparam  I9   =   I8 + 30 + 1;
//*************************************************************************
//--ºÚ:BADA Ó¥:D3A5 FP:4650 GA:4741 ¿ª:BFAA ·¢:B7A2 °å:B0E5 
//*************************************************************************
wire[7:0]uart_info[0:I9];  
assign uart_info[I1+0]   = 8'h02;                                      //--¿Õ¸ñ<×Ö·û>
assign uart_info[I1+1]   = 8'h0D;  
assign uart_info[I1+2]   = 8'h0A;  //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I1+3]   = 8'h0D;  
assign uart_info[I1+4]   = 8'h0A;  //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I1+5]   = 8'h0D;  
assign uart_info[I1+6]   = 8'h0A;  //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I1+7]   = 8'h20;  
assign uart_info[I1+8]   = 8'h20;  //--¿Õ¸ñ<×Ö·û>
assign uart_info[I1+9]   = 8'h20;  
assign uart_info[I1+10]  = 8'h20;  //--¿Õ¸ñ<×Ö·û>
assign uart_info[I1+11]  = 8'h20;  
assign uart_info[I1+12]  = 8'h20;  //--¿Õ¸ñ<×Ö·û>
assign uart_info[I1+13]  = 8'h0D;  
assign uart_info[I1+14]  = 8'h0A;  //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I1+15]  = 8'h20;  
assign uart_info[I1+16]  = 8'h20;  //--¿Õ¸ñ<×Ö·û>
assign uart_info[I1+17]  = 8'h20;  
assign uart_info[I1+18]  = 8'h20;  //--¿Õ¸ñ<×Ö·û>
assign uart_info[I1+19]  = 8'h20;  
assign uart_info[I1+20]  = 8'h20;  //--¿Õ¸ñ<×Ö·û>
assign uart_info[I1+21]  = 8'h20;  
assign uart_info[I1+22]  = 8'h20;  //--¿Õ¸ñ<×Ö·û>
assign uart_info[I1+23]  = 8'h20;  
assign uart_info[I1+24]  = 8'h20;  //--¿Õ¸ñ<×Ö·û>
assign uart_info[I1+25]  = 8'h20;                                      //--¿Õ¸ñ<×Ö·û>
assign uart_info[I1+26]  = 8'hBA;  
assign uart_info[I1+27]  = 8'hDA;  //--ºÚ
assign uart_info[I1+28]  = 8'hD3;  
assign uart_info[I1+29]  = 8'hA5;  //--Ó¥
assign uart_info[I1+30]  = 8'h46;  
assign uart_info[I1+31]  = 8'h50;  //--FP
assign uart_info[I1+32]  = 8'h47;  
assign uart_info[I1+33]  = 8'h41;  //--GA
assign uart_info[I1+34]  = 8'hBF;  
assign uart_info[I1+35]  = 8'hAA;  //--¿ª
assign uart_info[I1+36]  = 8'hB7;  
assign uart_info[I1+37]  = 8'hA2;  //--·¢
assign uart_info[I1+38]  = 8'hB0;  
assign uart_info[I1+39]  = 8'hE5;  //--°å
assign uart_info[I1+40]  = 8'h41;  
assign uart_info[I1+41]  = 8'h37;  //--A7
assign uart_info[I1+42]  = 8'h30;  
assign uart_info[I1+43]  = 8'h34;  //--04
assign uart_info[I1+44]  = 8'h20;                                      
assign uart_info[I1+45]  = 8'h20;  
assign uart_info[I1+46]  = 8'h20;  
assign uart_info[I1+47]  = 8'h20;  
assign uart_info[I1+48]  = 8'h20;  
assign uart_info[I1+49]  = 8'h0D;  
assign uart_info[I1+50]  = 8'h0A;  //--»Ø³µ»»ÐÐ<×Ö·û>
//*************************************************************************
//--×´Ì¬µÆ£ºD7B4CCACB5C6
//*************************************************************************
assign uart_info[I2+1]   = 8'h0D;  
assign uart_info[I2+2]   = 8'h0A;  //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I2+3]   = 8'hD7;  
assign uart_info[I2+4]   = 8'hB4;  //--×´
assign uart_info[I2+5]   = 8'hCC;  
assign uart_info[I2+6]   = 8'hAC;  //--Ì¬
assign uart_info[I2+7]   = 8'hB5;  
assign uart_info[I2+8]   = 8'hC6;  //--µÆ
assign uart_info[I2+9]   = 8'h20;                                      //--¿Õ¸ñ<×Ö·û>
assign uart_info[I2+10]  = 8'h20;                                      //--¿Õ¸ñ<×Ö·û>
assign uart_info[I2+11]  = 8'h20;                                      //--¿Õ¸ñ<×Ö·û>
assign uart_info[I2+12]  = 8'h3A;                                      //--:<×Ö·û>
assign uart_info[I2+13]  = 8'h20;                                  
assign uart_info[I2+14]  = 8'h20;                                  
assign uart_info[I2+15]  = 8'h20;
assign uart_info[I2+16]  = 8'h20;
assign uart_info[I2+17]  = 8'h20;
assign uart_info[I2+18]  = 8'h20;
assign uart_info[I2+19]  = 8'h20;
assign uart_info[I2+20]  = 8'h20;
assign uart_info[I2+21]  = 8'h20;
assign uart_info[I2+22]  = 8'h20;
assign uart_info[I2+23]  = led_r1[0];
assign uart_info[I2+24]  = led_r1[1];
assign uart_info[I2+25]  = 8'h20;                                     //--¿Õ¸ñ<×Ö·û>
assign uart_info[I2+26]  = led_r2[0]; 
assign uart_info[I2+27]  = led_r2[1];
assign uart_info[I2+28]  = 8'h20;  
assign uart_info[I2+29]  = 8'h20;  
assign uart_info[I2+30]  = 8'h20;          
//*******************************************************************
//--FPGAÎÂ¶È:46 50 47 41 CE C2 B6 C8  ¡ãC  :A1E343
//*******************************************************************
assign uart_info[I3+1]   = 8'h0D;  assign uart_info[I3+2]  = 8'h0A;  //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I3+3]   = 8'h0D;  assign uart_info[I3+4]  = 8'h0A;  //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I3+5]   = 8'h46;  assign uart_info[I3+6]  = 8'h50;  //--FP
assign uart_info[I3+7]   = 8'h47;  assign uart_info[I3+8]  = 8'h41;  //--GA 
assign uart_info[I3+9]   = 8'hCE;  assign uart_info[I3+10] = 8'hC2;  //--ÎÂ
assign uart_info[I3+11]  = 8'hB6;  assign uart_info[I3+12] = 8'hC8;  //--¶È
assign uart_info[I3+13]  = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I3+14]  = 8'h3A;                                    //--:<×Ö·û>
assign uart_info[I3+15]  = device_temp_h_r[(2 +1)*8-1:2 *8]; 
assign uart_info[I3+16]  = device_temp_h_r[(1 +1)*8-1:1 *8]; 
assign uart_info[I3+17]  = device_temp_h_r[(0 +1)*8-1:0 *8]; 
assign uart_info[I3+18]  = 8'h2E;                                    //--.<×Ö·û>
assign uart_info[I3+19]  = {4'h3,device_temp_l_r[3:0]}; 
assign uart_info[I3+20]  = 8'hA1; 
assign uart_info[I3+21]  = 8'hE3;   
assign uart_info[I3+22]  = 8'h43;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I3+23]  = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I3+24]  = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I3+25]  = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I3+26]  = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I3+27]  = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I3+28]  = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I3+29]  = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I3+30]  = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
//*******************************************************************
//--DDR³õÊ¼»¯:44 44 52 B3 F5 CA BC BB AF
//*******************************************************************
assign uart_info[I4+1]   = 8'h0D;  assign uart_info[I4+2]  = 8'h0A;  //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I4+3]   = 8'h0D;  assign uart_info[I4+4]  = 8'h0A;  //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I4+5]   = 8'h44;  assign uart_info[I4+6]  = 8'h44; assign uart_info[I4+7] = 8'h52;//--DDR
assign uart_info[I4+8]   = 8'hB3;  assign uart_info[I4+9]  = 8'hF5;  //--³õ
assign uart_info[I4+10]  = 8'hCA;  assign uart_info[I4+11] = 8'hBC;  //--Ê¼
assign uart_info[I4+12]  = 8'hBB;  assign uart_info[I4+13] = 8'hAF;  //--»¯
assign uart_info[I4+14]  = 8'h3A;                                    //--:<×Ö·û>
assign uart_info[I4+15]  = ddr_init_state[0]; 
assign uart_info[I4+16]  = ddr_init_state[1]; 
assign uart_info[I4+17]  = ddr_init_state[2]; 
assign uart_info[I4+18]  = ddr_init_state[3]; 
assign uart_info[I4+19]  = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I4+20]  = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
//*******************************************************************
//--DDR×Ô¼ì:44 44 52 D7 D4 BC EC
//*******************************************************************
assign uart_info[I5+1]   = 8'h0D;  assign uart_info[I5+2]  = 8'h0A;  //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I5+3]   = 8'h0D;  assign uart_info[I5+4]  = 8'h0A;  //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I5+5]   = 8'h44;  assign uart_info[I5+6]  = 8'h44; assign uart_info[I5+7] = 8'h52;//--DDR
assign uart_info[I5+8]   = 8'hD7;  assign uart_info[I5+9]  = 8'hD4;  //--×Ô
assign uart_info[I5+10]  = 8'hBC;  assign uart_info[I5+11] = 8'hEC;  //--¼ì
assign uart_info[I5+12]  = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I5+13]  = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I5+14]  = 8'h3A;                                    //--:<×Ö·û>
assign uart_info[I5+15]  = ddr_rw_state[0]; 
assign uart_info[I5+16]  = ddr_rw_state[1]; 
assign uart_info[I5+17]  = ddr_rw_state[2]; 
assign uart_info[I5+18]  = ddr_rw_state[3]; 
assign uart_info[I5+19]  = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I5+20]  = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
//*******************************************************************
//--DDRÐ´ÂëÂÊ:44 44 52 D0 B4 C2 EB C2 CA 3A 
//*******************************************************************1
assign uart_info[I6+1]   = 8'h0D; assign uart_info[I6+2]  = 8'h0A; //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I6+3]   = 8'h0D; assign uart_info[I6+4]  = 8'h0A; //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I6+5]   = 8'h44; assign uart_info[I6+6]  = 8'h44; assign uart_info[I6+7] = 8'h52;//--DDR
assign uart_info[I6+8]   = 8'hD0; assign uart_info[I6+9]  = 8'hB4; //--Ð´
assign uart_info[I6+10]  = 8'hCD; assign uart_info[I6+11] = 8'hB3; //--Í³
assign uart_info[I6+12]  = 8'hBC; assign uart_info[I6+13] = 8'hC6; //--¼Æ
assign uart_info[I6+14]  = 8'h3A;                                  //--:<×Ö·û>
assign uart_info[I6+15]  = w_code_rate_r[(11+1)*8-1:11*8]; 
assign uart_info[I6+16]  = w_code_rate_r[(10+1)*8-1:10*8]; 
assign uart_info[I6+17]  = w_code_rate_r[(9 +1)*8-1:9 *8]; 
assign uart_info[I6+18]  = w_code_rate_r[(8 +1)*8-1:8 *8]; 
assign uart_info[I6+19]  = w_code_rate_r[(7 +1)*8-1:7 *8];
assign uart_info[I6+20]  = w_code_rate_r[(6 +1)*8-1:6 *8];
assign uart_info[I6+21]  = w_code_rate_r[(5 +1)*8-1:5 *8];
assign uart_info[I6+22]  = w_code_rate_r[(4 +1)*8-1:4 *8];
assign uart_info[I6+23]  = w_code_rate_r[(3 +1)*8-1:3 *8];
assign uart_info[I6+24]  = w_code_rate_r[(2 +1)*8-1:2 *8];
assign uart_info[I6+25]  = w_code_rate_r[(1 +1)*8-1:1 *8];
assign uart_info[I6+26]  = w_code_rate_r[(0 +1)*8-1:0 *8];
assign uart_info[I6+27]  = 8'h20;
assign uart_info[I6+28]  = 8'h20;                                
assign uart_info[I6+29]  = 8'h20;                                //--¿Õ¸ñ<×Ö·û>
assign uart_info[I6+30]  = 8'h20;                                //--¿Õ¸ñ<×Ö·û>
//*******************************************************************
//--DDR¶ÁÂëÂÊ:44 44 52 B6 C1 C2 EB C2 CA 
//*******************************************************************
assign uart_info[I7+1]   = 8'h0D; assign uart_info[I7+2]  = 8'h0A; //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I7+3]   = 8'h0D; assign uart_info[I7+4]  = 8'h0A; //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I7+5]   = 8'h44; assign uart_info[I7+6]  = 8'h44; assign uart_info[I7+7] = 8'h52;//--DDR
assign uart_info[I7+8]   = 8'hB6; assign uart_info[I7+9]  = 8'hC1; //--¶Á
assign uart_info[I7+10]  = 8'hCD; assign uart_info[I7+11] = 8'hB3; //--Í³
assign uart_info[I7+12]  = 8'hBC; assign uart_info[I7+13] = 8'hC6; //--¼Æ
assign uart_info[I7+14]  = 8'h3A;                                  //--:<×Ö·û>
assign uart_info[I7+15]  = r_code_rate_r[(11+1)*8-1:11*8]; 
assign uart_info[I7+16]  = r_code_rate_r[(10+1)*8-1:10*8]; 
assign uart_info[I7+17]  = r_code_rate_r[(9 +1)*8-1:9 *8]; 
assign uart_info[I7+18]  = r_code_rate_r[(8 +1)*8-1:8 *8]; 
assign uart_info[I7+19]  = r_code_rate_r[(7 +1)*8-1:7 *8];
assign uart_info[I7+20]  = r_code_rate_r[(6 +1)*8-1:6 *8];
assign uart_info[I7+21]  = r_code_rate_r[(5 +1)*8-1:5 *8];
assign uart_info[I7+22]  = r_code_rate_r[(4 +1)*8-1:4 *8];
assign uart_info[I7+23]  = r_code_rate_r[(3 +1)*8-1:3 *8];
assign uart_info[I7+24]  = r_code_rate_r[(2 +1)*8-1:2 *8];
assign uart_info[I7+25]  = r_code_rate_r[(1 +1)*8-1:1 *8];
assign uart_info[I7+26]  = r_code_rate_r[(0 +1)*8-1:0 *8];
assign uart_info[I7+27]  = 8'h20;
assign uart_info[I7+28]  = 8'h20;                                
assign uart_info[I7+29]  = 8'h20;                                //--¿Õ¸ñ<×Ö·û>
assign uart_info[I7+30]  = 8'h20;                                //--¿Õ¸ñ<×Ö·û>
//*******************************************************************
//--°´:BC FC ¼ü:OD OA 1:31
//*******************************************************************
assign uart_info[I8+1]  = 8'h0D;  assign  uart_info[I8+2]  = 8'h0A;  //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I8+3]  = 8'h0D;  assign  uart_info[I8+4]  = 8'h0A;  //--»Ø³µ»»ÐÐ<×Ö·û>
assign uart_info[I8+5]  = 8'hB0;  assign  uart_info[I8+6]  = 8'hB4;  //--°´
assign uart_info[I8+7]  = 8'hBC;  assign  uart_info[I8+8]  = 8'hFC;  //--¼ü
assign uart_info[I8+9]  = 8'h20;                                   
assign uart_info[I8+10] = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I8+11] = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I8+12] = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I8+13] = 8'h20;                                    //--¿Õ¸ñ<×Ö·û>
assign uart_info[I8+14] = 8'h3A;                                    //--:<×Ö·û>
assign uart_info[I8+15] = key_r1[0];
assign uart_info[I8+16] = key_r1[1];
assign uart_info[I8+17] = key_r1[2];
assign uart_info[I8+18] = key_r1[3];
assign uart_info[I8+19] = key_r1[4];
assign uart_info[I8+20] = key_r1[5];  
assign uart_info[I8+21] = 8'h20;                                //--¿Õ¸ñ<×Ö·û>
assign uart_info[I8+22] = 8'h20;                                //--¿Õ¸ñ<×Ö·û>
assign uart_info[I8+23] = 8'h20;                                //--¿Õ¸ñ<×Ö·û>
assign uart_info[I8+24] = 8'h20;                                //--¿Õ¸ñ<×Ö·û>  
assign uart_info[I8+25] = 8'h20;                                //--¿Õ¸ñ<×Ö·û>
assign uart_info[I8+26] = 8'h20;                                //--¿Õ¸ñ<×Ö·û>   
assign uart_info[I8+27] = 8'h20;                                //--¿Õ¸ñ<×Ö·û>
assign uart_info[I8+28] = 8'h20;                                //--¿Õ¸ñ<×Ö·û>   
assign uart_info[I8+29] = 8'h20;                                //--¿Õ¸ñ<×Ö·û>
assign uart_info[I8+30] = 8'h20;                                //--¿Õ¸ñ<×Ö·û>   
//*************************************
//--1s ¶¨Ê±¼ÆÊýÆ÷
//*************************************
reg[27:0]time_cnt;
always @ (posedge clk or negedge rst_n)begin
   if(!rst_n)
      time_cnt <= 28'd0;
   else if(time_cnt == 28'd50000000) //--50Mhz 1s ¶¨Ê±¼ÆÊýÆ÷
      time_cnt <= 28'b0;
   else
      time_cnt <= time_cnt + 1'b1;
end
//--
reg char_fifo_rd_en_1r;
reg char_fifo_rd_en_2r;
always @ (posedge clk or negedge rst_n)begin
   if(!rst_n)begin
      char_fifo_rd_en_1r <= 1'd0;
      char_fifo_rd_en_2r <= 1'd0;
      end
   else begin
      char_fifo_rd_en_1r <= char_fifo_rd_en;
      char_fifo_rd_en_2r <= char_fifo_rd_en_1r;
      end
end
wire  char_fifo_rd_en_pos = (char_fifo_rd_en_1r==1'b1 && char_fifo_rd_en_2r==1'b0) ? 1'b1 :1'b0;
reg[8:0]req_cnt;
always @ (posedge clk or negedge rst_n)begin
   if(!rst_n)
      req_cnt <= 9'd0;
   else if(time_cnt == 28'd50000000)
      req_cnt <= 9'b0;
   else if(char_fifo_rd_en_pos==1'b1)
      req_cnt <= req_cnt + 1'b1;
end
always @ (posedge clk or negedge rst_n)begin
   if(!rst_n)
      char_fifo_dout <= 8'd0;
   else 
      char_fifo_dout <= uart_info[req_cnt];
end
always @ (posedge clk or negedge rst_n)begin
   if(!rst_n)
      char_fifo_empty <= 1'b1;
   else if(req_cnt>=I9)
      char_fifo_empty <= 1'b1;
   else
      char_fifo_empty <= 1'b0;
end

endmodule



