// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Wed Feb  5 18:49:56 2025
// Host        : Win102023HEYRFQ running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               J:/work/HY/Xilinx/A704/V1.0/PRJ/Project/top.runs/ddr_clk_synth_1/ddr_clk_stub.v
// Design      : ddr_clk
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tfgg484-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module ddr_clk(ddr3_clk, reset, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="ddr3_clk,reset,locked,clk_in1" */;
  output ddr3_clk;
  input reset;
  output locked;
  input clk_in1;
endmodule
