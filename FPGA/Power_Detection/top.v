module top(
    input   wire        sys_clk,
    input   wire        rst_n,

    output  wire        clk_adc,
    input   wire [0:11] adc_data_in,
    input   wire        OTR, // Over-Range Indicator

    output wire clk_out,
    output wire locked,
    input   wire        rx,  // UART接收
    output  wire        tx   // UART发送
);

wire [11:0] adc_data_out;
wire adc_data_ready;
wire [23:0] power_out;
wire power_out_valid;

// UART相关信号
wire [7:0] rx_data_out;
wire rx_valid;
wire rx_ready;
reg [7:0] tx_data_in;
reg tx_valid;
wire tx_ready;

// 状态机定义
reg [3:0] state;  // 扩展为4位以容纳更多状态
reg [23:0] power_data_buffer; // 缓存24位功率数据

// 状态机状态定义
localparam IDLE = 4'd0;
localparam SEND_BYTE0 = 4'd1;
localparam WAIT_BYTE0 = 4'd2;
localparam SEND_BYTE1 = 4'd3;
localparam WAIT_BYTE1 = 4'd4;
localparam SEND_BYTE2 = 4'd5;
localparam WAIT_BYTE2 = 4'd6;
localparam SEND_CR = 4'd7;     // 发送回车符
localparam WAIT_CR = 4'd8;     // 等待回车符发送完成
localparam SEND_LF = 4'd9;     // 发送换行符
localparam WAIT_LF = 4'd10;    // 等待换行符发送完成

// ASCII码定义
localparam CR = 8'h0D;  // 回车符 '\r'
localparam LF = 8'h0A;  // 换行符 '\n'

ADC ADC_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .adc_clk(sys_clk),
    .OTR(OTR),
    .adc_data_in(adc_data_in),
    .adc_data_out(adc_data_out),
    .adc_data_ready(adc_data_ready)
);

Power Power_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .power_in(adc_data_out),
    .power_in_valid(adc_data_ready),
    .power_out(power_out),
    .power_out_valid(power_out_valid)
);

uart uart_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .rx(rx),
    .tx(tx),
    .rx_data_out(rx_data_out),
    .rx_valid(rx_valid),
    .rx_ready(rx_ready),
    .tx_data_in(tx_data_in),
    .tx_valid(tx_valid),
    .tx_ready(tx_ready)
);


clk_wiz_0 clk_wiz_0_inst(
    .clk_in1(sys_clk),
    .clk_out1(clk_out),
    .clk_out2(clk_adc),
    .resetn(rst_n),
    .locked(locked)
);

// 状态机实现 - 将24位数据分三次发送，并在末尾添加换行
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        tx_valid <= 1'b0;
        tx_data_in <= 8'd0;
        power_data_buffer <= 24'd0;
    end else begin
        case (state)
            IDLE: begin
                tx_valid <= 1'b0;
                if (power_out_valid) begin
                    // 捕获新的功率数据
                    power_data_buffer <= power_out;
                    state <= SEND_BYTE0;
                end
            end
            
            SEND_BYTE0: begin
                // 发送低8位
                if (tx_ready) begin
                    tx_data_in <= power_data_buffer[23:16];
                    tx_valid <= 1'b1;
                    state <= WAIT_BYTE0;
                end
            end
            
            WAIT_BYTE0: begin
                // 等待第一个字节发送完成
                if (!tx_ready || tx_valid) begin
                    tx_valid <= 1'b0;
                end else begin
                    state <= SEND_BYTE1;
                end
            end
            
            SEND_BYTE1: begin
                // 发送中间8位
                if (tx_ready) begin
                    tx_data_in <= power_data_buffer[15:8];
                    tx_valid <= 1'b1;
                    state <= WAIT_BYTE1;
                end
            end
            
            WAIT_BYTE1: begin
                // 等待第二个字节发送完成
                if (!tx_ready || tx_valid) begin
                    tx_valid <= 1'b0;
                end else begin
                    state <= SEND_BYTE2;
                end
            end
            
            SEND_BYTE2: begin
                // 发送高8位
                if (tx_ready) begin
                    tx_valid <= 1'b1;                    
                    tx_data_in <= power_data_buffer[7:0];
                    state <= WAIT_BYTE2;
                end
            end
            
            WAIT_BYTE2: begin
                // 等待第三个字节发送完成
                if (!tx_ready || tx_valid) begin
                    tx_valid <= 1'b0;
                end else begin
                    state <= SEND_CR; // 发送完数据后，发送回车符
                end
            end
            
            SEND_CR: begin
                // 发送回车符
                if (tx_ready) begin
                    tx_data_in <= CR;
                    tx_valid <= 1'b1;
                    state <= WAIT_CR;
                end
            end
            
            WAIT_CR: begin
                // 等待回车符发送完成
                if (!tx_ready || tx_valid) begin
                    tx_valid <= 1'b0;
                end else begin
                    state <= SEND_LF;
                end
            end
            
            SEND_LF: begin
                // 发送换行符
                if (tx_ready) begin
                    tx_data_in <= LF;
                    tx_valid <= 1'b1;
                    state <= WAIT_LF;
                end
            end
            
            WAIT_LF: begin
                // 等待换行符发送完成
                if (!tx_ready || tx_valid) begin
                    tx_valid <= 1'b0;
                end else begin
                    state <= IDLE; // 完成一组数据和换行符的发送，回到空闲状态
                end
            end
            
            default: state <= IDLE;
        endcase
    end
end

endmodule