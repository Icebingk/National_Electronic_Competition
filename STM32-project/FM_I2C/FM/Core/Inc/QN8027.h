#ifndef __QN8027_H
#define __QN8027_H

#include "main.h"
#include "i2c.h"
// QN8027 I2C通信函数
void QN8027I2CRead(uint8_t* Data, uint8_t length);
void QN8027I2CWrite(uint8_t* Data, uint8_t length);

// QN8027 寄存器读写函数
void QN8027WriteReg(uint8_t Addr, uint8_t data);
void QN8027ReadReg(uint8_t Addr, uint8_t* data);

// QN8027 连续寄存器读写函数
void QN8027ReadRegisterDim(uint8_t Address, uint8_t* Reg, uint8_t Number);
void QN8027WriteRegisterDim(uint8_t Address, uint8_t* Reg, uint8_t Number);

// 读取所有寄存器内容
void QN8027ReadAllRegisters(uint8_t* Reg);

// 修改输出频率，但是不会启动发射
void QN8027SetOutputFrequency(float frq_MHz);

// 初始化QN8027寄存器
void QN8027Initialize(void);
#endif /* __QN8027_H */
