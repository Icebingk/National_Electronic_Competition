# 2025年全国电子设计大赛——3月9日最新

## 文件夹说明

- SPI文件夹内涵SPI主从机源文件、配置文件，和测试文件
- modulsim是用来仿真时许的
- spi-F407文件内各函数功能：
  1.【发送一个字节数据并返回接收的数据】uint8_t SPI_FPGA_SendByte(uint8_t byte);
  2.【读取一个字节数据】uint8_t SPI_FPGA_ReadByte(void);
  3.【发送并接收多个字节数据】void SPI_FPGA_TransmitReceive(uint8_t *txData, uint8_t *rxData, uint16_t size);
  4.【通过阻塞进行延时的函数】void Delay(__IO uint32_t nCount);
  5.【仅发送数据】void SPI_FPGA_Transmit(uint8_t *txData, uint16_t size);
  6.【仅接收数据】void SPI_FPGA_Receive(uint8_t *rxData, uint16_t size);

## 单片机引脚及功能

PC10---SCK
PC11---MISO
PC12---MOSI
PA04---CS

## 下次更新

- 将与单片机进行通信测试
- 统一指令
