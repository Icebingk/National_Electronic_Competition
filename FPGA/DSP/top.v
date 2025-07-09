// ADC9226模块的驱动程序
// 该模块用于接收ADC9226的12位数据，并在数据有效时输出
module top (
	input wire          sys_clk_p, // 65MHz clock
	input wire          sys_clk_n, // 65MHz clock
	input wire          rst_n, // Active low reset
    input wire [11:0]   adc_data, // Enable signal
    output reg [13:0]   data_out, // 12-bit ADC data output
    output wire         adc_clk, // ADC clock output
    output wire         dac_clk  // DAC clock output
);

reg  [11:0] adc_data_reg; // Register to hold ADC data
reg  [11:0] adc_data_reg2; // Register to hold ADC data
wire [49:0] data_out_r; // ADC data output
wire        data_ready; // ADC data output
wire        fir_valid; // FIR filter valid signal
assign fir_valid = adc_data_reg != adc_data_reg2; // FIR filter valid signal
//差分时钟
IBUFDS IBUFDS_inst (
      .O(sys_clk),   // 1-bit output: Buffer output
      .I(sys_clk_p),   // 1-bit input: Diff_p buffer input (connect directly to top-level port)
      .IB(sys_clk_n)  // 1-bit input: Diff_n buffer input (connect directly to top-level port)
   );

//存一下ADC进来的数据
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        adc_data_reg <= 12'b0; // Reset output data
        adc_data_reg2 <= 12'b0; // Reset output data
    end else begin
        adc_data_reg <= adc_data; // Output ADC data
        adc_data_reg2 <= adc_data_reg; // Output ADC data
    end
end

//输出数据高速DA
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 14'b0; // Reset output data
    end else if(data_ready) begin
        data_out <= data_out_r[22:9]; // Output ADC data with 2-bit padding
    end else begin
        data_out <= data_out; // Keep the previous output data
    end
end

// 处理ADC数据
 FIR fir_inst (
    .clk(sys_clk),
    .rst_n(rst_n),
    .data_valid(1'd1), // Always valid for this example
    .data_in(adc_data_reg), // 12-bit ADC data input
    .data_out(data_out_r), // 14-bit output data
    .data_ready(data_ready) // Data ready signal
);


endmodule