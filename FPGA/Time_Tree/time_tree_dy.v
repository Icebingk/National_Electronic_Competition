/*==============================================
* Function Name  : time_tree_dy.v
* Description    : 该模块是为了动态设计时钟树，
*                  主要听从于STM32F4的需求，
*                  通过动态配置实现不同频率的时钟输出
* input port     : 详细接口见下方注释
* output port    : 详细接口见下方注释
* Author         : ADBD
//==============================================*/

module time_tree_dy(
    input           sys_clk,        // 系统时钟
    input           rst_n,          // 低电平复位

    input           enable,         // 输入有效信号
    input [2:0]     clk_choise,     // 时钟选择信号
    input [7:0]     frq_num_int,    // 频率分频或者倍频数,整数部分
    input [7:0]     frq_num_float,  // 频率分频或者倍频数,小数部分

    output          error_sign,    // 错误信号
    output          clk_adc,       // 输出时钟1
    output          clk_dac,       // 输出时钟2
    output          clk_fir,       // 输出时钟3
    output          locked         // 锁定信号
);

reg enable_r; // 输入有效信号寄存器
always@(posedge sys_clk or negedge rst_n)begin
    if (!rst_n) begin
        enable_r <= 1'b0; // 复位时清零
    end else if (enable) begin
        enable_r <= 1'd1; // 保持输入有效信号
    end else begin
        enable_r <= 1'b0; // 输入无效时清零
    end
end

reg [10 : 0] s_axi_awaddr;    // AXI写地址
reg s_axi_awvalid;            // AXI写地址有效信号
wire s_axi_awready;           // AXI写地址就绪信号
reg [31 : 0] s_axi_wdata;     // AXI写数据
reg [3 : 0] s_axi_wstrb;      // AXI写数据掩码，控制写入哪几个字节
reg s_axi_wvalid;             // AXI写数据有效
wire s_axi_wready;            // AXI写数据就绪信号
wire [1 : 0] s_axi_bresp;     // AXI写响应信号,00表示成功，01表示写地址错误，10表示写数据错误，11表示其他错误
reg  [1 : 0] s_axi_bresp_r;   // AXI写响应信号的寄存器
wire s_axi_bvalid;            // AXI写响应有效信号
reg s_axi_bready;             // AXI写响应就绪信号

// 初始化AXI接口读取相关的寄存器
reg [10 : 0] s_axi_araddr = 11'd0;   // AXI读地址
reg s_axi_arvalid = 1'b0;            // AXI读地址有效信号
wire s_axi_arready;                  // AXI读地址就绪信号
wire [31 : 0] s_axi_rdata;           // AXI读数据
wire [1 : 0] s_axi_rresp;            // AXI读响应信号,00表示成功，01表示读地址错误，10表示读数据错误，11表示其他错误
wire s_axi_rvalid;                   // AXI读响应有效信号
reg s_axi_rready = 1'b0;             // AXI读响应就绪信号


localparam VCO_Freq     = 900; // VCO频率，单位MHz

// 状态机状态定义 
localparam IDLE         = 4'd0;// 空闲状态
localparam START        = 4'd1;// 数据加载
localparam WRITE        = 4'd2;// 有效拉高
localparam DATA_Accept  = 4'd3;// 等待就绪信号
localparam WRITE_OVER   = 4'd4;// 等待响应信号
localparam ERROR        = 4'd5;// 判断是否错误
localparam LOAD         = 4'd6;// 检查错误后重新加载寄存器

reg [3:0] axi_cstate,axi_nstate; // 控制AXI读写的状态机

// 状态机状态定义
wire IDLE_START =   enable_r; // IDLE状态下的有效信号
wire START_WRITE =  (axi_cstate == START); // IDLE状态下的开始信号
wire WAIT_Accept =  (axi_cstate == WRITE); // 等待AXI写地址和数据有效信号
wire Accept_OVER =  (axi_cstate == DATA_Accept) && (s_axi_awvalid == 1'b0 && s_axi_wvalid == 1'b0);// 等待握手协议完成，当地址和数据都传输完成
wire OVER_ERROR  =  (axi_cstate == WRITE_OVER) && (s_axi_bvalid && s_axi_bready); // 等待响应信号握手协议完成
wire ERROR_LOAD  =  (axi_cstate == ERROR) && (s_axi_bresp_r == 2'd0); // 判断完无错误进行数据加载
wire ERROR_IDLE  =  (axi_cstate == ERROR) && (s_axi_bresp_r != 2'd0 || s_axi_awaddr == 11'h25c); // 判断完有错误直接回到IDLE状态,加载数据直接回到IDLE状态
wire LOAD_WRITE  =  (axi_cstate == LOAD);

assign error_sign = (axi_cstate == ERROR) && (s_axi_bresp_r != 2'd0); // 错误信号，当状态机处于错误状态时为高

// 二段式状态机
always@(posedge sys_clk or negedge rst_n)begin
    if (!rst_n)begin
        axi_cstate <= IDLE;
    end else begin
        axi_cstate <= axi_nstate;
    end
end

// 数据缓存并处理
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        s_axi_awaddr <= 11'd0;
        s_axi_wdata <= 32'd0;
        s_axi_wstrb <= 4'd0;
    end else if (axi_cstate == START) begin
        s_axi_awaddr <= 11'h208 +  (clk_choise * 12);// 确定时钟分频的寄存器地址
        s_axi_wdata  <= {16'd0,frq_num_float,frq_num_int}; // 将整数和小数部分拼接成32位数据
        s_axi_wstrb  <= 4'b0011;
    end else if (axi_cstate == LOAD)begin
        s_axi_awaddr <= 11'h25C;
        s_axi_wdata <= 32'd3;
        s_axi_wstrb <= 4'd1;
    end else begin
        s_axi_awaddr <= s_axi_awaddr;
        s_axi_wdata  <= s_axi_wdata;
        s_axi_wstrb  <= s_axi_wstrb;
    end
end

// 控制握手协议
always@(posedge sys_clk or negedge rst_n)begin
    if (!rst_n) begin
        s_axi_awvalid <= 'b0;
        s_axi_wvalid  <= 'b0;
    end else if (axi_cstate == WRITE || axi_cstate == LOAD) begin
        s_axi_awvalid <= 'b1;
        s_axi_wvalid <= 'b1;
    end else if (axi_cstate == DATA_Accept)begin
        if (s_axi_awready && s_axi_awvalid)begin
            s_axi_awvalid <= 'b0;
        end else begin
            s_axi_awvalid <= s_axi_awvalid;
        end
         // valid已确保为高，但仍检查完整握手条件以确保代码健壮性
        if (s_axi_wready && s_axi_wvalid)begin
            s_axi_wvalid <= 'b0;
        end else begin
            s_axi_wvalid <= s_axi_wvalid;
        end
    end else begin
        s_axi_awvalid <= s_axi_awvalid;
        s_axi_wvalid  <= s_axi_wvalid;
    end
end

// 响应信号处理
always@(posedge sys_clk or negedge rst_n)begin
    if (!rst_n) begin
        s_axi_bready <= 'b0;
        s_axi_bresp_r <= 2'd0; // 响应信号寄存器初始化
    end else if (axi_cstate == WRITE_OVER) begin
        s_axi_bready <= 'b1; // 响应信号就绪
        if(s_axi_bvalid)begin
            s_axi_bresp_r <= s_axi_bresp; 
        end else begin
            s_axi_bresp_r <= s_axi_bresp_r; 
        end
    end else begin
        s_axi_bready <= 'b0;
        s_axi_bresp_r <= s_axi_bresp_r; 
    end
end

// 第二级状态机控制
always@(*)begin
        case(axi_cstate)
            IDLE:if (IDLE_START) begin
                axi_nstate = START;
            end else begin
                axi_nstate = axi_cstate;
            end
            START:if(START_WRITE) begin
                axi_nstate = WRITE;
            end else begin
                axi_nstate = axi_cstate;
            end
            WRITE:if(WAIT_Accept) begin
                axi_nstate = DATA_Accept;
            end else begin
                axi_nstate = axi_cstate;
            end
            DATA_Accept:if(Accept_OVER) begin
                axi_nstate = WRITE_OVER;
            end else begin
                axi_nstate = axi_cstate;
            end
            WRITE_OVER:if (OVER_ERROR)begin
                axi_nstate = ERROR;
            end else begin
                axi_nstate = axi_cstate;
            end
            ERROR:if(ERROR_IDLE)begin
                axi_nstate = IDLE;
            end else if(ERROR_LOAD) begin
                axi_nstate = LOAD;
            end else begin
                axi_nstate = axi_cstate;
            end
            LOAD:if (LOAD_WRITE)begin
                axi_nstate = WRITE; // 进入WRITE状态，控制寄存器重载
            end else begin
                axi_nstate = axi_cstate;
            end
            default: begin
                axi_nstate = IDLE; // 默认状态，防止状态机进入未知状态
            end
        endcase
end

clk_module  clk_module_inst (
    .s_axi_aclk(sys_clk),
    .s_axi_aresetn(rst_n),
    
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),

    .s_axi_araddr(s_axi_araddr),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),

    .clk_out1(clk_dac),
    .clk_out2(clk_adc),
    .clk_out3(clk_fir),
    .locked(locked),
    .clk_in1(sys_clk)
  );

endmodule 
