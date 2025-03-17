//////////////////////////////////////////////////////////////////////////
// 文件说明：SPI指令集定义文件
// 更新时间：2025年3月14日
// 说明：包含所有SPI从机通信所需的指令码定义
//////////////////////////////////////////////////////////////////////////

// 设备ID常量定义
`define FPGA_ID         8'h88    // FPGA设备ID: 1000_1000B

// 基本指令码
`define READ_ID         8'hFF    // 读设备ID指令: 1111_1111B
`define WRITE_REG       8'h88    // 写寄存器指令: 1000_1000B
`define READ_REG        8'h89    // 读寄存器指令: 1000_1001B
`define READ_STATUS     8'h8F    // 读寄存器状态: 1000_1111B

// 连续读写指令
`define CONT_WRITE_START 8'hA8   // 连续写开始: 1010_1000B
`define CONT_WRITE_STOP  8'h98   // 连续写停止: 1001_1000B
`define CONT_READ_START  8'hA9   // 连续读开始: 1010_1001B
`define CONT_READ_STOP   8'h99   // 连续读停止: 1001_1001B

// 操作控制指令基础码及掩码
`define START_OP_BASE   8'h8C    // 开始操作基础码: 1000_1100B
`define STOP_OP_BASE    8'h0C    // 结束操作基础码: 0000_1100B
`define OP_MASK         8'h70    // 操作编号掩码: 0111_0000B
`define OP_SHIFT        4        // 操作编号位移量

// 时钟控制指令基础码及掩码
`define CLOCK_BASE      8'h0A    // 时钟控制基础码: 0000_1010B
`define CLOCK_MODE_MASK 8'h80    // 时钟模式掩码(倍频/分频): 1000_0000B
`define CLOCK_DEV_MASK  8'h70    // 设备编号掩码: 0111_0000B
`define CLOCK_DEV_SHIFT 4        // 设备编号位移量

// 分频/倍频模式定义
`define DIV_MODE        1'b0     // 分频模式
`define MULT_MODE       1'b1     // 倍频模式

// 辅助宏，用于生成开始/结束操作指令
// 使用示例: `GEN_START_OP(3) 生成开启第3个操作的指令码
`define GEN_START_OP(op_id) (`START_OP_BASE | (((op_id) & 7) << `OP_SHIFT))
`define GEN_STOP_OP(op_id)  (`STOP_OP_BASE | (((op_id) & 7) << `OP_SHIFT))

// 辅助宏，用于生成时钟控制指令
// 使用示例: `GEN_DIV_CLOCK(2) 生成控制第2号设备分频的指令
// 使用示例: `GEN_MULT_CLOCK(5) 生成控制第5号设备倍频的指令
`define GEN_DIV_CLOCK(dev_id)  (`CLOCK_BASE | (((dev_id) & 7) << `CLOCK_DEV_SHIFT))
`define GEN_MULT_CLOCK(dev_id) (`CLOCK_BASE | `CLOCK_MODE_MASK | (((dev_id) & 7) << `CLOCK_DEV_SHIFT))

// 预定义操作ID常量，方便使用
`define OP_ADC_SAMPLE   3'h0    // ADC采样操作ID
`define OP_DAC_OUTPUT   3'h1    // DAC输出操作ID
`define OP_DATA_PROC    3'h2    // 数据处理操作ID
`define OP_FILTER       3'h3    // 滤波操作ID
`define OP_FFT          3'h4    // FFT操作ID
`define OP_CUSTOM1      3'h5    // 自定义操作1
`define OP_CUSTOM2      3'h6    // 自定义操作2
`define OP_CUSTOM3      3'h7    // 自定义操作3

// 预定义设备ID常量
`define DEV_ADC         3'h0    // ADC设备ID
`define DEV_DAC         3'h1    // DAC设备ID
`define DEV_SENSOR1     3'h2    // 传感器1设备ID
`define DEV_SENSOR2     3'h3    // 传感器2设备ID
`define DEV_CUSTOM1     3'h4    // 自定义设备1
`define DEV_CUSTOM2     3'h5    // 自定义设备2
`define DEV_CUSTOM3     3'h6    // 自定义设备3
`define DEV_CUSTOM4     3'h7    // 自定义设备4