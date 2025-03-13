// 基本指令码定义
`define READ_ID       8'hFF  // 读设备ID指令：1111_1111B
`define WRITE_REG     8'h88  // 写寄存器指令：1000_1000B
`define READ_REG      8'h89  // 读寄存器指令：1000_1001B
`define READ_STATUS   8'h8F  // 读寄存器状态指令：1000_1111B

// 连续读写指令的基本码，实际使用时需设置高3位表示读写数量
`define WRITE_MULTI_BASE 8'h88  // 连续写寄存器基本指令：1000_1000B
`define READ_MULTI_BASE  8'h89  // 连续读寄存器基本指令：1000_1001B

// 连续读写指令的掩码及偏移，用于设置连续操作数量
`define MULTI_COUNT_MASK  8'h70  // 连续读写数量掩码：0111_0000B
`define MULTI_COUNT_SHIFT 4      // 连续读写数量位移量

// 开始/结束操作指令的基本码
`define START_OPERATION_BASE 8'hEC  // 开始某操作基本指令：1XXX_1100B
`define STOP_OPERATION_BASE  8'h0C  // 结束某操作基本指令：0XXX_1100B

// 开始/结束操作指令的掩码及偏移，用于设置操作编号
`define OPERATION_ID_MASK  8'h70   // 操作编号掩码：0111_0000B
`define OPERATION_ID_SHIFT 4       // 操作编号位移量

// 设置时钟频率指令
`define SET_CLOCK_BASE     8'h0E   // 设置时钟频率基本指令：0XXX_1110B
`define CLOCK_MODE_MASK    8'h80   // 分频/倍频模式掩码：1000_0000B
`define CLOCK_VALUE_MASK   8'h70   // 分频/倍频值掩码：0111_0000B
`define CLOCK_VALUE_SHIFT  4       // 分频/倍频值位移量

// 分频/倍频模式定义
`define CLOCK_DIV_MODE     1'b0    // 分频模式
`define CLOCK_MULT_MODE    1'b1    // 倍频模式

// 辅助宏，用于生成连续读写指令
`define GEN_WRITE_MULTI(count) (`WRITE_MULTI_BASE | (((count-1) & 8'h7) << `MULTI_COUNT_SHIFT))
`define GEN_READ_MULTI(count)  (`READ_MULTI_BASE | (((count-1) & 8'h7) << `MULTI_COUNT_SHIFT))

// 辅助宏，用于生成开始/结束操作指令
`define GEN_START_OP(id) (`START_OPERATION_BASE | ((id & 8'h7) << `OPERATION_ID_SHIFT))
`define GEN_STOP_OP(id)  (`STOP_OPERATION_BASE | ((id & 8'h7) << `OPERATION_ID_SHIFT))

// 辅助宏，用于生成时钟设置指令
`define GEN_CLOCK_DIV(value)  (`SET_CLOCK_BASE | ((value & 8'h7) << `CLOCK_VALUE_SHIFT))
`define GEN_CLOCK_MULT(value) (`SET_CLOCK_BASE | `CLOCK_MODE_MASK | ((value & 8'h7) << `CLOCK_VALUE_SHIFT))
