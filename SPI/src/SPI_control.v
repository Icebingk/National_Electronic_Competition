////////////////////////////////////////////////////////////////////////////
////更新时间：      2025年2月5日
////文件说明：      通过SPI模块，发送/接收 1byte的定长指令数据
////               先发送设备ID，接收到返回的设备ID后，再发送指令，代表一次指令传输完毕
////指令集说明：    参照处理器设计
////////////////////////////////////////////////////////////////////////////
module SPI_control (
    input clk,
    input rst,

    output wire [7:0] seg_number,
    output wire [7:0] seg_choice,

    input DCLK,
    input MOSI,
    output MISO,
    input nCS
);
localparam  IDLE  = 0,
            START = 1,
            TRANS = 2,
            OVER  = 3;

reg [3:0] state, next_state;
reg [31:0] seg_number_in;
reg CPOL = 0;
reg CPHA = 0;
reg [7:0] data_in;
reg data_in_vld;
wire [7:0] data_out;
reg  [7:0] data_out_r;
wire data_out_vld;
reg [3:0] cnt;
reg data_reflash;

always @(posedge clk or posedge rst) begin
    if (rst)begin
        data_reflash <= 1'b0;
    end else if (data_out_vld)begin
        data_reflash <= 1'b1;
    end else begin
        data_reflash <= 1'b0;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt <= 4'd0;
    end else if (cnt == 4'd5) begin
        cnt <= 4'd0;
    end else if (data_out_vld) begin
        cnt <= cnt + 1'b1;
    end else begin
        cnt <= 4'd0;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_in <=  8'h00;
        data_in_vld <= 1'b0;
    end else if (cnt == 4'd4)begin
        data_in <=  8'h88;
        data_in_vld <= 1'b1;
    end else begin
        data_in <=  8'h00;
        data_in_vld <= 1'b0;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_out_r <= 8'h00;
    end else if (data_reflash)begin
        data_out_r <= data_out;
    end else begin
        data_out_r <= data_out_r;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        seg_number_in <= 32'h00000000;
    end else if (data_out_vld)begin
        seg_number_in[31:0] <= {seg_number_in[23:0], data_out_r[7:0]};
    end else begin
        seg_number_in[31:0] <= seg_number_in[31:0];
    end
end

SPI_slave  SPI_slave_inst (
    .clk(clk),
    .rst_n(~rst),
    .data_in(data_in),
    .data_in_vld(data_in_vld),
    .data_out(data_out),
    .data_out_vld(data_out_vld),
    .nCS(nCS),
    .DCLK(DCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .CPOL(CPOL),
    .CPHA(CPHA)
    );

segdisplay  segdisplay_inst (
    .clk(clk),
    .rst_n(~rst),
    .seg_number_in(seg_number_in),
    .seg_number(seg_number),
    .seg_choice(seg_choice)
  );

endmodule

