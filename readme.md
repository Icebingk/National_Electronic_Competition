# 2025年全国电子设计大赛——3月9日最新

## 文件夹说明

- SPI文件夹内涵SPI主从机源文件、配置文件，和测试文件
- modulsim是用来仿真时许的
- spi-F407文件内各函数功能：
1. 【发送一个字节数据并返回接收的数据】uint8_t SPI_FPGA_SendByte(uint8_t byte);
2. 【读取一个字节数据】uint8_t SPI_FPGA_ReadByte(void);
3. 【发送并接收多个字节数据】void SPI_FPGA_TransmitReceive(uint8_t *txData, uint8_t *rxData, uint16_t size);
4. 【通过阻塞进行延时的函数】void Delay(__IO uint32_t nCount);
5. 【仅发送数据】void SPI_FPGA_Transmit(uint8_t *txData, uint16_t size);
6. 【仅接收数据】void SPI_FPGA_Receive(uint8_t *rxData, uint16_t size);
7. PA10 PA11 PA12三位输入的二进制数，对应以下7种模式：
    （1）发送一个字节
    （2）接收一个字节
    （3）连续发送10个字节
    （4）连续接收10个字节
    （5）发送并接收10个字节
    （6）连续发送12个字节，在发送完第5个字节后突然拉高片选信号，继续发送完第10个字节后又突然拉低片选信号
    （7）连续接收12个字节，在接收完第5个字节后突然拉高片选信号，继续接收完第10个字节后又突然拉低片选信号。



## 单片机引脚及功能

PC10---SCK
PC11---MISO
PC12---MOSI
PA04---CS
PA5 PA6---时钟模式输出
PA10 PA11 PA12---收发模式输入选择

## 下次更新

- 将与单片机进行通信测试
- 统一指令
