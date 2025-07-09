module FIR #(
    parameter DATA_WIDTH = 12,           // 输入数据位宽
    parameter COEFF_WIDTH = 32,          // 系数位宽
    parameter TAPS = 43,                 // 滤波器阶数(必须为奇数以利用对称性)
    parameter ACCUM_EXTRA_BITS = 6, // 累加可能增加的位数
    parameter OUTPUT_WIDTH = DATA_WIDTH + COEFF_WIDTH + ACCUM_EXTRA_BITS
)(
    input  wire                             clk,       // 时钟信号
    input  wire                             rst_n,     // 复位信号，低电平有效
    input  wire                             data_valid, // 输入数据有效
    input  wire signed [DATA_WIDTH-1:0]     data_in,   // 输入数据
    output reg                              data_ready, // 输出数据有效
    output reg signed [OUTPUT_WIDTH-1:0]    data_out   // 输出数据
);

    // --- 参数计算 ---
    localparam HALF_TAPS_IDX = (TAPS-1) / 2;
    localparam NUM_SYMM_COEFFS = HALF_TAPS_IDX + 1; // = 22 for TAPS=43
    localparam NUM_SYMM_COEFFS_LOG2 = $clog2(NUM_SYMM_COEFFS); // = 5 for TAPS=43
    // Adder tree parameters
    localparam ADD_STAGE1_OUTS = (NUM_SYMM_COEFFS + 1) / 2; // = 11
    localparam ADD_STAGE2_OUTS = (ADD_STAGE1_OUTS + 1) / 2; // = 6
    localparam ADD_STAGE3_OUTS = (ADD_STAGE2_OUTS + 1) / 2; // = 3

    // --- 存储 ---
    reg signed [COEFF_WIDTH-1:0] coeffs [0:NUM_SYMM_COEFFS-1];
    reg signed [DATA_WIDTH-1:0] input_shift_reg [0:TAPS-1];

    // --- Block RAM 加载系数 ---
    reg [NUM_SYMM_COEFFS_LOG2-1:0] bram_addr;
    reg bram_rd_en;
    wire [COEFF_WIDTH-1:0] bram_data;
    reg [NUM_SYMM_COEFFS_LOG2-1:0] coeff_index;
    reg loading_coeffs;
    reg init_done;

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
    reg data_valid_p1;
    // 阶段 1 -> 2 (Pre-add outputs)
    reg signed [DATA_WIDTH:0] pre_add_results_p2 [0:HALF_TAPS_IDX-1];
    reg signed [DATA_WIDTH-1:0] center_tap_data_p2;
    reg data_valid_p2;
    // 阶段 2 -> 3 (Multiply outputs)
    reg signed [OUTPUT_WIDTH-1:0] mult_results_p3 [0:NUM_SYMM_COEFFS-1];
    reg data_valid_p3;
    // 阶段 3 -> 4 (Adder Tree Stage 1 outputs)
    reg signed [OUTPUT_WIDTH-1:0] add_stage1_regs [0:ADD_STAGE1_OUTS-1];
    reg data_valid_p4;
    // 阶段 4 -> 5 (Adder Tree Stage 2 outputs)
    reg signed [OUTPUT_WIDTH-1:0] add_stage2_regs [0:ADD_STAGE2_OUTS-1];
    reg data_valid_p5;
    // 阶段 5 -> 6 (Adder Tree Stage 3 outputs)
    reg signed [OUTPUT_WIDTH-1:0] add_stage3_regs [0:ADD_STAGE3_OUTS-1];
    reg data_valid_p6;

    integer i, j; // Use j for generate block if needed

    // --- 主处理逻辑 ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // --- 复位 ---
            bram_addr <= 0;
            coeff_index <= 0;
            loading_coeffs <= 1'b1;
            bram_rd_en <= 1'b1;
            init_done <= 1'b0;

            data_ready <= 1'b0;
            data_out <= {OUTPUT_WIDTH{1'b0}};
            data_valid_p1 <= 1'b0;
            data_valid_p2 <= 1'b0;
            data_valid_p3 <= 1'b0;
            data_valid_p4 <= 1'b0;
            data_valid_p5 <= 1'b0;
            data_valid_p6 <= 1'b0;

            for (i = 0; i < TAPS; i = i + 1) input_shift_reg[i] <= {DATA_WIDTH{1'b0}};
            for (i = 0; i < HALF_TAPS_IDX; i = i + 1) pre_add_results_p2[i] <= 0;
             center_tap_data_p2 <= 0;
            for (i = 0; i < NUM_SYMM_COEFFS; i = i + 1) mult_results_p3[i] <= 0;
            for (i = 0; i < ADD_STAGE1_OUTS; i = i + 1) add_stage1_regs[i] <= 0;
            for (i = 0; i < ADD_STAGE2_OUTS; i = i + 1) add_stage2_regs[i] <= 0;
            for (i = 0; i < ADD_STAGE3_OUTS; i = i + 1) add_stage3_regs[i] <= 0;

        end else begin
            // --- 系数加载 ---
            if (!init_done) begin
                // ... (系数加载逻辑不变) ...
                if (loading_coeffs) begin
                    if (bram_rd_en) begin
                        bram_rd_en <= 1'b0;
                    end else begin
                        coeffs[coeff_index] <= bram_data;
                        if (coeff_index == NUM_SYMM_COEFFS-1) begin
                            loading_coeffs <= 1'b0;
                            init_done <= 1'b1;
                        end else begin
                            coeff_index <= coeff_index + 1;
                            bram_addr <= bram_addr + 1;
                            bram_rd_en <= 1'b1;
                        end
                    end
                end
            end
            // --- 流水线处理 ---
            else begin
                // **阶段 0: 输入移位**
                if (data_valid) begin
                    for (i = TAPS-1; i > 0; i = i - 1) begin
                        input_shift_reg[i] <= input_shift_reg[i-1];
                    end
                    input_shift_reg[0] <= data_in;
                end
                data_valid_p1 <= data_valid;

                // **阶段 1: 预加法 -> 输出到 P2 寄存器**
                if (data_valid_p1) begin
                    for (i = 0; i < HALF_TAPS_IDX; i = i + 1) begin
                        pre_add_results_p2[i] <= input_shift_reg[i] + input_shift_reg[TAPS-1-i];
                    end
                    center_tap_data_p2 <= input_shift_reg[HALF_TAPS_IDX];
                end
                data_valid_p2 <= data_valid_p1;

                // **阶段 2: 乘法 -> 输出到 P3 寄存器**
                if (data_valid_p2) begin
                    for (i = 0; i < HALF_TAPS_IDX; i = i + 1) begin
                        mult_results_p3[i] <= pre_add_results_p2[i] * coeffs[i];
                    end
                    mult_results_p3[HALF_TAPS_IDX] <= center_tap_data_p2 * coeffs[HALF_TAPS_IDX];
                    // 如果 NUM_SYMM_COEFFS > HALF_TAPS_IDX + 1 (理论上不会，但为了完整性)
                    // for (i = HALF_TAPS_IDX + 1; i < NUM_SYMM_COEFFS; i = i + 1) begin
                    //    mult_results_p3[i] <= 0; // Or handle appropriately if needed
                    // end
                end
                data_valid_p3 <= data_valid_p2;

                // **阶段 3: 加法树第一级 -> 输出到 P4 寄存器**
                if (data_valid_p3) begin
                    for (i = 0; i < ADD_STAGE1_OUTS; i = i + 1) begin
                        if ((2*i + 1) < NUM_SYMM_COEFFS) begin // Check if pair exists
                            add_stage1_regs[i] <= mult_results_p3[2*i] + mult_results_p3[2*i+1];
                        end else begin // Odd number of inputs, pass last one through
                            add_stage1_regs[i] <= mult_results_p3[2*i];
                        end
                    end
                end
                data_valid_p4 <= data_valid_p3;

                // **阶段 4: 加法树第二级 -> 输出到 P5 寄存器**
                if (data_valid_p4) begin
                    for (i = 0; i < ADD_STAGE2_OUTS; i = i + 1) begin
                        if ((2*i + 1) < ADD_STAGE1_OUTS) begin // Check if pair exists
                            add_stage2_regs[i] <= add_stage1_regs[2*i] + add_stage1_regs[2*i+1];
                        end else begin // Odd number of inputs, pass last one through
                            add_stage2_regs[i] <= add_stage1_regs[2*i];
                        end
                    end
                end
                data_valid_p5 <= data_valid_p4;

                // **阶段 5: 加法树第三级 -> 输出到 P6 寄存器**
                if (data_valid_p5) begin
                    for (i = 0; i < ADD_STAGE3_OUTS; i = i + 1) begin
                        if ((2*i + 1) < ADD_STAGE2_OUTS) begin // Check if pair exists
                            add_stage3_regs[i] <= add_stage2_regs[2*i] + add_stage2_regs[2*i+1];
                        end else begin // Odd number of inputs, pass last one through
                            add_stage3_regs[i] <= add_stage2_regs[2*i];
                        end
                    end
                end
                data_valid_p6 <= data_valid_p5;

                // **阶段 6: 最终累加 (剩余部分) + 输出**
                // Now we need to sum the results from add_stage3_regs (3 values for TAPS=43)
                // This final summation happens combinatorially before the output register.
                // For better timing, this should also be pipelined if ADD_STAGE3_OUTS > 2.
                if (data_valid_p6) begin
                    // Sum the 3 results from the 3rd stage
                    // This could be pipelined further if needed
                    if (ADD_STAGE3_OUTS == 1) begin
                        data_out <= add_stage3_regs[0];
                    end else if (ADD_STAGE3_OUTS == 2) begin
                         data_out <= add_stage3_regs[0] + add_stage3_regs[1];
                    end else if (ADD_STAGE3_OUTS == 3) begin
                         data_out <= add_stage3_regs[0] + add_stage3_regs[1] + add_stage3_regs[2];
                    end else begin
                         // Handle larger cases if necessary, likely needs more pipeline stages
                         // For now, assume simple sum for small remaining numbers
                         data_out <= add_stage3_regs[0]; // Placeholder for more complex logic
                         for (i = 1; i < ADD_STAGE3_OUTS; i = i + 1) begin
                             data_out <= data_out + add_stage3_regs[i]; // Combinatorial sum
                         end
                    end
                end else begin
                    data_out <= {OUTPUT_WIDTH{1'b0}}; // Or keep previous value? Depends on spec.
                end
                data_ready <= data_valid_p6; // Output is ready one cycle after stage 6 inputs are valid

            end // end if(init_done)
        end // end else (!rst_n)
    end // end always

endmodule