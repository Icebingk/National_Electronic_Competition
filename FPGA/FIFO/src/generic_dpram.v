module generic_dpram #(
  parameter aw = 4,
  parameter dw = 8
) (
  input               rclk , // 读时钟
  input               rrst , //读复位（无用）
  input               rce, oe, // oe无用，rce 读片选
  input      [aw-1:0] raddr, waddr,
  output reg [dw-1:0] dout , // 输出数据
  input               wclk, wrst, wce, we, // we 写使能，wrst rrst wce无用，
  input      [dw-1:0] di     // 数据输入
);

  localparam DEPTH = (1<<aw);

  reg [dw-1:0] mem[DEPTH-1:0]; 
  reg [dw-1:0] i;
  initial begin 
    for (i=0;i<DEPTH;i=i+1) mem[i] = i; 
  end

  always @ ( posedge wclk ) if (we ) mem[waddr]<=di;
  always @ ( posedge rclk ) if (rce) dout <= mem[raddr];

endmodule
