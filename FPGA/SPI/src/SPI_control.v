////////////////////////////////////////////////////////////////////////////
////更新时间：      2025年2月5日
////文件说明：      通过SPI模块，发送/接收 1byte的定长指令数据
////                先发送设备ID，接收到返回的设备ID后，再发送指令，代表一次指令传输完毕
////指令集说明：    参照处理器设计
////////////////////////////////////////////////////////////////////////////
module SPI_control (
    input clk,
    input rst,
    
    output wire [7:0] seg_number,
    output wire [7:0] seg_choice,
    
    input CPHA,
    input CPOL,
    input DCLK,
    input MOSI,
    output MISO,
    input nCS,

    output wire [2:0] mode
);
reg [7:0] data_in = 8'b0;
reg data_in_vld = 1'b0;
wire [7:0] data_out;
reg  [7:0] data_out_r[9:0];
wire data_out_vld;
reg [31:0] seg_number_in;
reg [3:0]  data_out_cnt;
reg [25:0] time_cnt;
reg time_cnt_flag;
reg [2:0] seg_cnt;
assign mode = 3'd3;

always@(posedge clk or posedge rst) begin
    if (rst) begin
        time_cnt <= 26'b0;
        time_cnt_flag <= 'b0;
    end else if (time_cnt == 26'd50_000_000 - 1) begin
        time_cnt <= 26'b0;
        time_cnt_flag <= 'b1;
    end else begin
        time_cnt <= time_cnt + 1;
        time_cnt_flag <= 'b0;
    end
end

genvar i;
generate
    for (i = 0; i < 10; i = i + 1)begin
        always @(posedge clk or posedge rst) begin
            if (rst) begin
                data_out_r[i] <= 8'b0;
            end else if (data_out_vld) begin
                if (i == data_out_cnt) begin
                    data_out_r[i] <= data_out;
                end
            end else begin
                data_out_r[i] <= data_out_r[i];
            end
        end
    end
endgenerate

always @(posedge clk or posedge rst) begin
    if (rst)begin
        data_out_cnt <= 4'b0;
    end else if (data_out_cnt == 4'd10)begin
        data_out_cnt <= 4'b0;
    end else if (data_out_vld) begin
        data_out_cnt <= data_out_cnt + 1;
    end else begin
        data_out_cnt <= data_out_cnt;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        seg_cnt <= 3'b0;
    end else if (time_cnt_flag) begin
        if (seg_cnt == 3'd6) begin
            seg_cnt <= 3'b0;
        end else begin
            seg_cnt <= seg_cnt + 1;
        end
    end else begin
        seg_cnt <= seg_cnt;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        seg_number_in <= 32'b0;
    end else begin
        seg_number_in[31:0] <= {data_out_r[seg_cnt][7:0],data_out_r[seg_cnt+1][7:0],data_out_r[seg_cnt+2][7:0],data_out_r[seg_cnt+3][7:0]};
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

