/*==============================================
* Function Name  : delay_soft.v
* Description    : 该模块用于延时处理，主要用于软延时。
* input port     : clk(系统时钟), kin(输入信号)
* output port    : kout(延时输出信号)
* Author         : ADBD
//==============================================*/

module delay_soft(
	input clk,kin,
	output reg kout
);

parameter  [31:0]  del = 1_000_000;					//clk = 100MHz, del 10ms.
reg[31:0] kh,kl;

always @(posedge clk)begin
	if(!kin)
		kl<=kl+1'b1;
	else 
		kl<=4'b0000;
end

always @(posedge clk)begin
	if(kin)
		kh<=kh+1'b1;
	else 
		kh<=4'b0000;
end

always @(posedge clk)begin
	if(kh > del)
		kout<=1'b1;
	else if(kl > del)
		kout=1'b0;
end

endmodule 

