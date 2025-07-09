/*==============================================
* Function Name  : led.v
* Description    : 这个模块实现了LED灯的循环点亮效果。
*                  每隔一段时间，点亮一个LED灯，依次循环点亮LD1到LD8。
* input port     : clk(系统时钟), rst_n(复位信号)
* output port    : led(LED输出信号，控制8个LED，低电平点亮)
* Author         : ADBD
//==============================================*/

module led(
    input   wire                clk,		//时钟信号
    input   wire                rst_n,		//复位信号
    output  reg     [7:0]       led			//LD1 - LD8
    );

reg         [31:0]       count;
reg			[3:0]        stat;

//状态切换模式
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        count <= 0;
		led <= 8'b1111_1111;
		stat <= 0;
    end else begin
        if(count == 5000000 - 1) begin
            count <= 0;
				led <= ~(1 << stat);
				if(stat == 8) begin
				    stat <= 0;
				end else begin
					 stat <= stat + 1;
				end
        end else begin
            count <= count + 1;
        end
    end
end

endmodule
