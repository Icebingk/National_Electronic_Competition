/*==============================================
* Function Name  : key_con.v
* Description    : 
*
* input port     :
* output port    :
* Author         :
//==============================================*/

module key_con (
	input            clk,
	input            rst_n,
	input            key_in,

	output  [31:0]   fre_k
);

reg     [31:0]   fre_k_buf;
reg     [31:0]   fre;
wire             key_out;

assign  fre_k = fre;

always @(posedge clk) begin
	if (!rst_n) begin
		fre <= 1000;			// 1Hz
	end
	else begin
		if (!key_out) begin
			fre <= fre + 1'b1;
		end
		else begin
			fre <= fre ;
		end
	end
end

delay_soft key_delay_U(
	.clk(clk),
	.kin(key_in),
	.kout(key_out)
);

endmodule 

