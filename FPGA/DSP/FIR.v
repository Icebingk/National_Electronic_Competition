module FIR #(
    parameter DATA_WIDTH = 12,           // 输入数据位宽
    parameter COEFF_WIDTH = 32,          // 系数位宽
    parameter TAPS = 15,                 // 滤波器阶数(必须为奇数以利用对称性)
    parameter ACCUM_EXTRA_BITS = 6,      // 累加可能增加的位数
    parameter OUTPUT_WIDTH = DATA_WIDTH + COEFF_WIDTH + ACCUM_EXTRA_BITS// = 50
)(
    input  wire                             clk,       // 时钟信号
    input  wire                             rst_n,     // 复位信号，低电平有效
    input  wire                             data_valid, // 输入数据有效
    input  wire signed [DATA_WIDTH-1:0]     data_in,   // 输入数据
    output reg                              data_ready, // 输出数据有效
    output reg signed [OUTPUT_WIDTH-1:0]    data_out   // 输出数据
);

    // --- 参数计算 ---
    localparam HALF_TAPS_IDX = (TAPS-1) / 2;            // 半数滤波器系数索引 (=7 for TAPS=15)
    localparam NUM_SYMM_COEFFS = HALF_TAPS_IDX + 1;     // 利用对称性后的系数数量 (=8 for TAPS=15)
    localparam NUM_SYMM_COEFFS_LOG2 = $clog2(NUM_SYMM_COEFFS); // 系数地址位宽 (=3 for TAPS=15)
    
    // 加法树参数
    localparam ADD_STAGE1_OUTS = (NUM_SYMM_COEFFS + 1) / 2; // 第一级加法树输出 (=4)
    localparam ADD_STAGE2_OUTS = (ADD_STAGE1_OUTS + 1) / 2; // 第二级加法树输出 (=2)
    localparam ADD_STAGE3_OUTS = (ADD_STAGE2_OUTS + 1) / 2; // 第三级加法树输出 (=1)
    // 额外流水线处理参数
    localparam MAX_GROUPS = 4;                          // 最多支持的分组数
    localparam GROUP_SIZE = 3;                          // 每组累加的元素数

    // --- 存储 ---
    reg signed [COEFF_WIDTH-1:0] coeffs [0:NUM_SYMM_COEFFS-1];        // 滤波器系数
    reg signed [DATA_WIDTH-1:0] input_shift_reg [0:TAPS-1];           // 输入移位寄存器

    // --- Block RAM 加载系数 ---
    reg [NUM_SYMM_COEFFS_LOG2-1:0] bram_addr;           // 地址线
    reg bram_rd_en;                                     // 读使能信号
    wire [COEFF_WIDTH-1:0] bram_data;                  // 系数数据
    reg [NUM_SYMM_COEFFS_LOG2-1:0] coeff_index;         // 当前加载系数索引
    reg loading_coeffs;                                 // 系数加载过程标志
    reg init_done;                                      // 初始化完成标志

    // 实例化Block RAM
    blk_mem_gen_0 coeffs_bram (
        .clka(clk), 
        .ena(1'b1), 
        .addra(bram_addr), 
        .douta(bram_data),
        .wea(1'b0), 
        .dina({COEFF_WIDTH{1'b0}})
    );

    // --- 流水线阶段寄存器 ---
    // 阶段 0 -> 1
    reg data_valid_p1;                                  // 阶段1数据有效标志
    
    // 阶段 1 -> 2 (预加法输出)
    reg signed [DATA_WIDTH:0] pre_add_results_p2 [0:HALF_TAPS_IDX-1]; // 对称输入相加结果
    reg signed [DATA_WIDTH-1:0] center_tap_data_p2;                   // 中心抽头数据 
    reg data_valid_p2;                                                // 阶段2数据有效标志
    
    // 阶段 2 -> 3 (乘法输出)
    reg signed [OUTPUT_WIDTH-1:0] mult_results_p3 [0:NUM_SYMM_COEFFS-1]; // 乘法结果
    reg data_valid_p3;                                                  // 阶段3数据有效标志
    
    // 阶段 3 -> 4 (加法树第一级输出)
    reg signed [OUTPUT_WIDTH-1:0] add_stage1_regs [0:ADD_STAGE1_OUTS-1]; // 加法树第一级寄存器
    reg data_valid_p4;                                                  // 阶段4数据有效标志
    
    // 阶段 4 -> 5 (加法树第二级输出)
    reg signed [OUTPUT_WIDTH-1:0] add_stage2_regs [0:ADD_STAGE2_OUTS-1]; // 加法树第二级寄存器
    reg data_valid_p5;                                                  // 阶段5数据有效标志
    
    // 阶段 5 -> 6 (加法树第三级输出)
    reg signed [OUTPUT_WIDTH-1:0] add_stage3_regs [0:ADD_STAGE3_OUTS-1]; // 加法树第三级寄存器
    reg data_valid_p6;                                                  // 阶段6数据有效标志
    
    // 阶段 6 -> 7 (部分累加结果 - 用于大规模加法）
    reg signed [OUTPUT_WIDTH-1:0] add_stage4_partial_sums [0:MAX_GROUPS-1]; // 部分累加寄存器
    reg [2:0] add_stage4_count;                                           // 部分累加组数
    reg data_valid_p7;                                                    // 阶段7数据有效标志

    // 临时变量
    integer i;                                          // 循环计数器

    // --- 主处理逻辑 ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // --- 复位所有寄存器和状态 ---
            bram_addr <= 0;
            coeff_index <= 0;
            loading_coeffs <= 1'b1;
            bram_rd_en <= 1'b1;
            init_done <= 1'b0;

            // 复位输出和流水线状态信号
            data_ready <= 1'b0;
            data_out <= {OUTPUT_WIDTH{1'b0}};
            data_valid_p1 <= 1'b0;
            data_valid_p2 <= 1'b0;
            data_valid_p3 <= 1'b0;
            data_valid_p4 <= 1'b0;
            data_valid_p5 <= 1'b0;
            data_valid_p6 <= 1'b0;
            data_valid_p7 <= 1'b0;
            
            // 清空所有流水线寄存器
            for (i = 0; i < TAPS; i = i + 1) input_shift_reg[i] <= {DATA_WIDTH{1'b0}};
            for (i = 0; i < HALF_TAPS_IDX; i = i + 1) pre_add_results_p2[i] <= 0;
            center_tap_data_p2 <= 0;
            for (i = 0; i < NUM_SYMM_COEFFS; i = i + 1) mult_results_p3[i] <= 0;
            for (i = 0; i < ADD_STAGE1_OUTS; i = i + 1) add_stage1_regs[i] <= 0;
            for (i = 0; i < ADD_STAGE2_OUTS; i = i + 1) add_stage2_regs[i] <= 0;
            for (i = 0; i < ADD_STAGE3_OUTS; i = i + 1) add_stage3_regs[i] <= 0;
            for (i = 0; i < MAX_GROUPS; i = i + 1) add_stage4_partial_sums[i] <= 0;
            add_stage4_count <= 0;
            
        end else begin
            // --- 系数加载 ---
            if (!init_done) begin
                if (loading_coeffs) begin
                    if (bram_rd_en) begin
                        // 正在等待BRAM读取，下一周期数据有效
                        bram_rd_en <= 1'b0;
                    end else begin
                        // BRAM数据有效，保存系数
                        coeffs[coeff_index] <= bram_data;
                        
                        if (coeff_index == NUM_SYMM_COEFFS-1) begin
                            // 所有系数加载完成
                            loading_coeffs <= 1'b0;
                            init_done <= 1'b1;
                        end else begin
                            // 准备加载下一个系数
                            coeff_index <= coeff_index + 1;
                            bram_addr <= bram_addr + 1;
                            bram_rd_en <= 1'b1;
                        end
                    end
                end
            end else begin
                // --- 初始化完成，开始流水线处理 ---
                
                // **阶段 0: 输入移位**
                if (data_valid) begin
                    // 移位寄存器操作
                    for (i = TAPS-1; i > 0; i = i - 1) begin
                        input_shift_reg[i] <= input_shift_reg[i-1];
                    end
                    input_shift_reg[0] <= data_in;  // 新数据进入移位寄存器
                end
                data_valid_p1 <= data_valid;  // 传递数据有效标志

                // **阶段 1: 预加法 -> 输出到 P2 寄存器**
                if (data_valid_p1) begin
                    // 利用对称性，对称位置的输入相加
                    for (i = 0; i < HALF_TAPS_IDX; i = i + 1) begin
                        pre_add_results_p2[i] <= input_shift_reg[i] + input_shift_reg[TAPS-1-i];
                    end
                    // 中心抽头直接传递（不需要相加）
                    center_tap_data_p2 <= input_shift_reg[HALF_TAPS_IDX];
                end
                data_valid_p2 <= data_valid_p1;  // 传递数据有效标志

                // **阶段 2: 乘法 -> 输出到 P3 寄存器**
                if (data_valid_p2) begin
                    // 将预加法结果与对应系数相乘
                    for (i = 0; i < HALF_TAPS_IDX; i = i + 1) begin
                        mult_results_p3[i] <= pre_add_results_p2[i] * coeffs[i];
                    end
                    // 中心抽头与对应系数相乘
                    mult_results_p3[HALF_TAPS_IDX] <= center_tap_data_p2 * coeffs[HALF_TAPS_IDX];
                end
                data_valid_p3 <= data_valid_p2;  // 传递数据有效标志

                // **阶段 3: 加法树第一级 -> 输出到 P4 寄存器**
                if (data_valid_p3) begin
                    for (i = 0; i < ADD_STAGE1_OUTS; i = i + 1) begin
                        if ((2*i + 1) < NUM_SYMM_COEFFS) begin // 检查是否存在配对
                            // 每次取两个相邻结果相加
                            add_stage1_regs[i] <= mult_results_p3[2*i] + mult_results_p3[2*i+1];
                        end else begin // 奇数输入，直接传递最后一个
                            add_stage1_regs[i] <= mult_results_p3[2*i];
                        end
                    end
                end
                data_valid_p4 <= data_valid_p3;  // 传递数据有效标志

                // **阶段 4: 加法树第二级 -> 输出到 P5 寄存器**
                if (data_valid_p4) begin
                    for (i = 0; i < ADD_STAGE2_OUTS; i = i + 1) begin
                        if ((2*i + 1) < ADD_STAGE1_OUTS) begin // 检查是否存在配对
                            // 每次取两个相邻结果相加
                            add_stage2_regs[i] <= add_stage1_regs[2*i] + add_stage1_regs[2*i+1];
                        end else begin // 奇数输入，直接传递最后一个
                            add_stage2_regs[i] <= add_stage1_regs[2*i];
                        end
                    end
                end
                data_valid_p5 <= data_valid_p4;  // 传递数据有效标志

                // **阶段 5: 加法树第三级 -> 输出到 P6 寄存器**
                if (data_valid_p5) begin
                    for (i = 0; i < ADD_STAGE3_OUTS; i = i + 1) begin
                        if ((2*i + 1) < ADD_STAGE2_OUTS) begin // 检查是否存在配对
                            // 每次取两个相邻结果相加
                            add_stage3_regs[i] <= add_stage2_regs[2*i] + add_stage2_regs[2*i+1];
                        end else begin // 奇数输入，直接传递最后一个
                            add_stage3_regs[i] <= add_stage2_regs[2*i];
                        end
                    end
                end
                data_valid_p6 <= data_valid_p5;  // 传递数据有效标志

                // **阶段 6: 部分累加或直接输出**
                if (data_valid_p6) begin
                    if (ADD_STAGE3_OUTS <= 3) begin
                        // 当输出数量少于等于3个时，直接计算最终结果
                        if (ADD_STAGE3_OUTS == 1) begin
                            data_out <= add_stage3_regs[0];
                        end else if (ADD_STAGE3_OUTS == 2) begin
                            data_out <= add_stage3_regs[0] + add_stage3_regs[1];
                        end else begin // ADD_STAGE3_OUTS == 3
                            data_out <= add_stage3_regs[0] + add_stage3_regs[1] + add_stage3_regs[2];
                        end
                        // 小规模累加，直接设置数据就绪
                        data_ready <= 1'b1;
                    end else begin
                        // 当输出数量大于3个时，需要额外流水线阶段
                        // 计算分组数量（向上取整）
                        add_stage4_count <= (ADD_STAGE3_OUTS + GROUP_SIZE - 1) / GROUP_SIZE; 
                        
                        // 将结果分组，每GROUP_SIZE(3)个为一组，计算部分和
                        for (i = 0; i < MAX_GROUPS; i = i + 1) begin
                            if (i*GROUP_SIZE+2 < ADD_STAGE3_OUTS) begin 
                                // 完整的3元素组
                                add_stage4_partial_sums[i] <= add_stage3_regs[i*GROUP_SIZE] + add_stage3_regs[i*GROUP_SIZE+1] + add_stage3_regs[i*GROUP_SIZE+2];
                            end else if (i*GROUP_SIZE+1 < ADD_STAGE3_OUTS) begin 
                                // 2元素组
                                add_stage4_partial_sums[i] <= add_stage3_regs[i*GROUP_SIZE] + add_stage3_regs[i*GROUP_SIZE+1];
                            end else if (i*GROUP_SIZE < ADD_STAGE3_OUTS) begin 
                                // 1元素组
                                add_stage4_partial_sums[i] <= add_stage3_regs[i*GROUP_SIZE];
                            end else begin
                                // 未使用的部分设为0
                                add_stage4_partial_sums[i] <= 0;
                            end
                        end
                        // 大规模累加需要额外一个周期，延迟数据就绪信号
                        data_ready <= 1'b0;
                    end
                end

                // 只有当ADD_STAGE3_OUTS>3时才需要阶段7
                data_valid_p7 <= (data_valid_p6 && (ADD_STAGE3_OUTS > 3)); 
                // **阶段 7: 最终累加部分和输出** (仅当累加规模大时才激活)
                if (data_valid_p7) begin
                    // 根据部分和的数量选择不同的累加方式
                    case (add_stage4_count)
                        1: data_out <= add_stage4_partial_sums[0];
                        2: data_out <= add_stage4_partial_sums[0] + add_stage4_partial_sums[1];
                        3: data_out <= add_stage4_partial_sums[0] + add_stage4_partial_sums[1] + add_stage4_partial_sums[2];
                        4: data_out <= add_stage4_partial_sums[0] + add_stage4_partial_sums[1] + add_stage4_partial_sums[2] + add_stage4_partial_sums[3];
                        default: data_out <= add_stage4_partial_sums[0]; // 默认情况
                    endcase
                    // 最终累加完成，设置数据就绪信号
                    data_ready <= 1'b1;
                end

            end // end if(init_done)
        end // end else (!rst_n)
    end // end always

endmodule