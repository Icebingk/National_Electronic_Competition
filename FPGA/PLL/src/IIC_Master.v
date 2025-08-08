module iic_master (
    input wire sys_clk,          // 系统时钟
    input wire rst_n,            // 低电平有效的复位信号
    input wire [31:0] data_in,   // 要发送的32位数据
    input wire start_trans,      // 开始传输信号
    output reg trans_done,       // 传输完成指示
    output reg scl,              // I2C时钟线
    output reg sda,              // I2C数据线 (单向输出)
    output reg le                // 锁存使能信号，在数据发送后拉高一个IIC时钟长度
);

// 参数定义
parameter SYS_CLK_FREQ = 50_000_000;  // 系统时钟频率，例如50MHz
parameter I2C_CLK_FREQ = 100_000;   // I2C时钟频率，例如100KHz
parameter CLK_DIV = SYS_CLK_FREQ / (I2C_CLK_FREQ * 4) - 1; // 分频系数

// I2C状态机状态
localparam IDLE         = 3'd0;  // 空闲状态
localparam START        = 3'd1;  // 起始条件
localparam DATA_SEND    = 3'd2;  // 发送32位数据
localparam LE_ACTIVE    = 3'd3;  // LE激活状态
localparam STOP         = 3'd4;  // 停止条件

// 寄存器定义
reg [2:0] state, next_state;
reg [15:0] clk_cnt;        // 时钟计数器
reg [5:0] bit_cnt;         // 位计数器 (0-31)
reg [31:0] data_reg;       // 数据寄存器
reg [1:0] le_cycle_cnt;    // LE周期计数器

// 时钟分频计数器
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_cnt <= 16'd0;
    end else if (state != IDLE || start_trans) begin
        if (clk_cnt == CLK_DIV) begin
            clk_cnt <= 16'd0;
        end else begin
            clk_cnt <= clk_cnt + 16'd1;
        end
    end else begin
        clk_cnt <= 16'd0;
    end
end

// I2C时钟周期分为4部分，每个部分持续CLK_DIV个系统时钟周期
// 00: SCL上升沿之前
// 01: SCL高电平
// 10: SCL下降沿之前
// 11: SCL低电平
reg [1:0] scl_phase;

// SCL生成 - 修改为在LE_ACTIVE状态下不生成SCL
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        scl_phase <= 2'b00;
        scl <= 1'b1;
    end else if (state == LE_ACTIVE) begin
        // LE_ACTIVE状态下SCL保持高电平
        scl <= 1'b1;
        // 继续更新scl_phase用于计时
        if (clk_cnt == CLK_DIV) begin
            case (scl_phase)
                2'b00: scl_phase <= 2'b01;
                2'b01: scl_phase <= 2'b10;
                2'b10: scl_phase <= 2'b11;
                2'b11: scl_phase <= 2'b00;
            endcase
        end
    end else if (clk_cnt == CLK_DIV) begin
        case (scl_phase)
            2'b00: begin
                scl <= 1'b1;
                scl_phase <= 2'b01;
            end
            2'b01: begin
                scl <= 1'b1;
                scl_phase <= 2'b10;
            end
            2'b10: begin
                scl <= 1'b0;
                scl_phase <= 2'b11;
            end
            2'b11: begin
                scl <= 1'b0;
                scl_phase <= 2'b00;
            end
        endcase
    end
end

// 状态机 - 状态寄存器
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// 状态机 - 组合逻辑
always @(*) begin
    case (state)
        IDLE: begin
            if (start_trans)
                next_state = START;
            else
                next_state = IDLE;
        end
        START: begin
            if (clk_cnt == CLK_DIV && scl_phase == 2'b01)
                next_state = DATA_SEND;
            else
                next_state = START;
        end
        DATA_SEND: begin
            if (clk_cnt == CLK_DIV && scl_phase == 2'b11 && bit_cnt == 32)
                next_state = LE_ACTIVE;
            else
                next_state = DATA_SEND;
        end
        LE_ACTIVE: begin
            // 保持LE状态一个完整的I2C时钟周期（4个scl_phase）
            if (clk_cnt == CLK_DIV && scl_phase == 2'b11 && le_cycle_cnt == 1)
                next_state = STOP;
            else
                next_state = LE_ACTIVE;
        end
        STOP: begin
            if (clk_cnt == CLK_DIV && scl_phase == 2'b01)
                next_state = IDLE;
            else
                next_state = STOP;
        end
        default: next_state = IDLE;
    endcase
end

// 状态机 - 输出逻辑
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        sda <= 1'b1;
        bit_cnt <= 6'd0;
        data_reg <= 32'd0;
        trans_done <= 1'b0;
        le <= 1'b0;
        le_cycle_cnt <= 2'd0;
    end else begin
        case (state)
            IDLE: begin
                sda <= 1'b1;
                bit_cnt <= 6'd0;
                le <= 1'b0;
                le_cycle_cnt <= 2'd0;
                if (start_trans) begin
                    data_reg <= data_in;
                    trans_done <= 1'b0;
                end
            end
            START: begin
                le <= 1'b0;
                if (clk_cnt == CLK_DIV) begin
                    case (scl_phase)
                        2'b00: begin
                            sda <= 1'b1;
                        end
                        2'b01: begin
                            sda <= 1'b0; // START condition: SDA从高到低变化，而SCL保持高
                        end
                        default: sda <= 1'b0;
                    endcase
                end
            end
            DATA_SEND: begin
                le <= 1'b0;
                if (clk_cnt == CLK_DIV && scl_phase == 2'b11) begin
                    bit_cnt <= bit_cnt + 6'd1;
                    // 在SCL低电平阶段末尾更新SDA值，为下一位数据做准备
                    if (bit_cnt < 32) begin
                        sda <= data_reg[31 - bit_cnt];
                    end
                end else if (clk_cnt == CLK_DIV && scl_phase == 2'b00) begin
                    // 在SCL上升沿之前确保第一位数据准备好
                    if (bit_cnt == 0) begin
                        sda <= data_reg[31];
                    end
                end
                // 移除原来的连续赋值代码
                // sda <= data_reg[31 - bit_cnt]; // 删除这一行
            end
            LE_ACTIVE: begin
                // 激活LE信号一个完整的I2C时钟周期
                le <= 1'b1;
                sda <= 1'b0; // 为STOP条件做准备
                
                // 计数一个完整的SCL周期
                if (clk_cnt == CLK_DIV && scl_phase == 2'b11) begin
                    le_cycle_cnt <= le_cycle_cnt + 2'd1;
                end
            end
            STOP: begin
                le <= 1'b0; // 关闭LE信号
                le_cycle_cnt <= 2'd0;
                
                if (clk_cnt == CLK_DIV) begin
                    case (scl_phase)
                        2'b00: sda <= 1'b0;
                        2'b01: begin
                            sda <= 1'b1; // STOP condition: SDA从低到高变化，而SCL保持高
                            trans_done <= 1'b1;
                        end
                        default: sda <= 1'b1;
                    endcase
                end
            end
        endcase
    end
end

endmodule