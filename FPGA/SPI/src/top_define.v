///////////////////////////////////////////////////////////////////////////
// 说明：工程顶层文件，包含工程所有参数
///////////////////////////////////////////////////////////////////////////
//SPI_slave.v的参数
`define DATA_WIDTH 16    //一次传输的数据（不包括地址和指令）
`define DATA_ADDR  4    //用于数据的宽度,2**DATA_ADDR=DATA_WIDTH
`define ADDR_WIDTH 16   //地址宽度
`define ODDR_WIDTH 16    //指令宽度
`define DEVICE_CONTROL_WIDTH 8 //设备控制指令宽度
//SPI_master.v的参数
`define STATE_WIDTH 3  //状态机状态位宽,实际根据数据的宽度，状态有2*DATA_WIDTH个，所有状态机位宽n，满足2**n=2*DATA_WIDTH
`define SPI_CLK_DIV 16  //SPI时钟分频
`define SPI_CLK_EDGE 5  //SPI时钟边沿计数器位宽

// SPI指令集定义
`define SPI_Instruction             16'hD000 //指令集起始地址
`define DATA                        16'h8000 //数据起始地址
//设备ID
`define SPI_DEVICE_ID               16'hD0FE //设备ID
`define SPI_DEVICE_ID_READ          16'hD0EA //设备ID读取指令
// 读写指令
//////单次读写
`define SPI_READ                    16'hD0E8 //读指令
`define SPI_WRITE                   16'hD0E9 //写指令
//////连续读写
`define SPI_WRITE_CONTINUOUS_REQ    16'hD0ED //连续写请求指令
`define SPI_WRITE_CONTINUOUS_END    16'hD0EC //连续写结束指令
`define SPI_READ_CONTINUOUS_REQ     16'hD0EF //连续读请求指令
`define SPI_READ_CONTINUOUS_END     16'hD0EE //连续读结束指令
//////读写状态指令
`define SPI_READ_REG_STATE          16'hD0E0 //读状态指令

//控制指令
//////控制指令开始
`define SPI_CONTROL_REQ             16'hD0A8 //控制指令开始
`define SPI_CONTROL_END             16'hD0A0 //控制指令结束
//////控制设备频率
`define SPI_CONTROL_FREQ_DIV        16'hD0B0 //频率分频系数
`define SPI_CONTROL_FREQ_MUL        16'hD0B8 //频率倍频系数

`define SPI_STATE                   8