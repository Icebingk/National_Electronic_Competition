# 2025年全国电子设计大赛——3月9日最新

## 文件夹说明
```
|-- FPGA
|   |-- DAC
|   |-- DSP
|   |-- FIFO
|   |-- IIC
|   |-- SPI
|   |-- Vivado
|   |-- basic_model
|   |-- modulsim
|   |-- uart
|-- STM32-project
|   |-- spi-F407
|   |-- spi-F429
|-- doc
|   |-- AD9764高速DAC(125M 14bit)模块资料
|   |-- CT137X_PIN_X.xlsx
|   |-- 器件购买清单.xlsx
|   |-- 数字滤波器的MATLAB与FPGA实现
|-- readme.md
```
### FPGA

#### SPI

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

#### FIFO

- 往届集创赛所用的FIFO，异步不同时间域

#### DAC

- DAC控制模块，将DAC当作DDS使用

#### DSP

- [ ] 数字FIR滤波器，未开发完善，等待器件到达进行校验和可移植化处理

#### Basic_module

- 常用基本模块，包括定时器、蜂鸣器、摁键边沿检测、呼吸灯、LED灯控制、8个8位数码管、sram读写控制等

#### IIC

- 一些用IIC通信协议外设

#### UART

- 异步步全双工串口，可收发字符串

## STM32-Project片机引脚及功能

PC10---SCK
PC11---MISO
PC12---MOSI
PA04---CS
PA5 PA6---时钟模式输出
PA10 PA11 PA12---收发模式输入选择

## TI单片机引脚与功能
PA0---I2C.SCL
PA1---I2C.SDA
PB16---SCK
PB15---PICO
PB14---POCI
PA2---CS
PA21 PA22 PA23---收发模式输入选择

## 下次更新

- 将与单片机进行通信测试
- 统一指令
- 将DAC进行数字低通滤波，并且使用sin补偿

## 工作方式

1. 首先将main分支同步到你的工作分支
2. 在你的工作分支上面进行编辑
3. 将你的工作分支同步到远程服务器
4. 发起合并请求
5. 审核后合并到main分支当中

Tips：

 Git 提交的粒度要足够小（原则上每次 commit 不超过 200 行，要求在 Pull Request 中看到的每个commit 都是细粒度的，比如每完成一个功能或修复一个 bug 尽量都进行提交。
