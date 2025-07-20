/*==============================================
* Function Name  : delay_soft
* Description    : 软件延时去抖动，去除毛刺
* Remark         : 
* Author         : 
//==============================================*/
module delay_soft(clk,kin,kout);
input clk,kin;
output kout;

reg kout;
reg[31:0] kh,kl;

parameter  [31:0]  del = 1000000;					//clk = 100MHz, del 10ms.


always @(posedge clk)
begin
	if(!kin)
		kl<=kl+1'b1;
	else 
		kl<=4'b0000;
end

always @(posedge clk)
begin
	if(kin)
		kh<=kh+1'b1;
	else 
		kh<=4'b0000;
end

always @(posedge clk)
begin
	if(kh > del)
		kout<=1'b1;
	else 
		if(kl > del)
			kout=1'b0;
end

endmodule 

