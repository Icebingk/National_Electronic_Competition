///////////////////////////////////////////////////////////////////////////
// 说明：工程顶层文件，包含工程所有参数
///////////////////////////////////////////////////////////////////////////
`define DATA_WIDTH 8    //一次传输的数据（不包括地址和指令）
`define DATA_ADDR  3    //用于数据的宽度,2**DATA_ADDR=DATA_WIDTH
`define ADDR_WIDTH 16   //地址宽度
`define ODDR_WIDTH 4    //指令宽度

//SPI_master.v的参数
`define STATE_WIDTH 3  //状态机状态位宽,实际根据数据的宽度，状态有2*DATA_WIDTH个，所有状态机位宽n，满足2**n=2*DATA_WIDTH
`define SPI_CLK_DIV 16  //SPI时钟分频
`define SPI_CLK_EDGE 5  //SPI时钟边沿计数器位宽