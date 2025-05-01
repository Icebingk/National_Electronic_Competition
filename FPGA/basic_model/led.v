// File Name: led.v
// Description: LED灯闪烁
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
