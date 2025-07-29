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
`define SPI_Instruction             16'hFF00 //指令集起始地址
`define DATA                        16'h8000 //数据起始地址
//设备ID
`define SPI_DEVICE_ID               16'hFFFE //设备ID
`define SPI_DEVICE_ID_READ          16'hFFEA //设备ID读取指令

//控制指令
//////控制指令开始
`define SPI_CONTROL_REQ             16'hFFA8 //控制指令开始
`define SPI_CONTROL_END             16'hFFA0 //控制指令结束

// A类指令，只需要控
`define A_Class                     4'hA // A类指令标识
`define IDREAD                      3'h1
`define ADC_Read                    3'h2
`define FIR_ADC                     3'h3
`define FIR_DAC                     3'h4
`define PFD                         3'h5

// B类指令，需要数据交换
`define B_Class                     4'hB // B类指令标识
`define TIME_SET                    3'h6
`define DAC_Write                   3'h7

`define Turn_ON                     'b1
`define Turn_OFF                    'b0
//////控制设备频率
`define SPI_CONTROL_FREQ_DIV        16'hFFB0 //频率分频系数
`define SPI_CONTROL_FREQ_MUL        16'hFFB8 //频率倍频系数

`define SPI_STATE                   8

// AD和DA驱动模块定义
`define AD_DATA_WIDTH 12 // AD驱动模块数据位宽
`define DA_DATA_WIDTH 14 // DA驱动模块数据位宽
`define sin_rom_add   5  // 正弦波ROM地址位宽
`define sin_rom_max   2**`sin_rom_add - 1 // 最大地址

