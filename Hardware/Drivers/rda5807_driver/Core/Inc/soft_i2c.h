#ifndef SOFT_I2C_H
#define SOFT_I2C_H

#include "stm32f4xx_hal.h"

// I2C GPIO端口和引脚定义
#define SOFT_I2C_SCL_PORT   GPIOC
#define SOFT_I2C_SCL_PIN    GPIO_PIN_0
#define SOFT_I2C_SDA_PORT   GPIOC
#define SOFT_I2C_SDA_PIN    GPIO_PIN_1

// I2C时钟延时定义
#define SOFT_I2C_DELAY_US   2

// I2C操作结果定义
#define SOFT_I2C_OK         0
#define SOFT_I2C_ERROR      1

// 基本I2C时序函数
void Soft_I2C_Init(void);
void Soft_I2C_Start(void);
void Soft_I2C_Stop(void);
void Soft_I2C_Send_Byte(uint8_t byte);
uint8_t Soft_I2C_Read_Byte(void);
uint8_t Soft_I2C_Wait_Ack(void);
void Soft_I2C_Ack(void);
void Soft_I2C_NAck(void);

// 高级I2C操作函数
uint8_t Soft_I2C_Writes_Bytes(uint8_t device_addr, uint8_t reg_addr, uint8_t *data, uint16_t len);
uint8_t Soft_I2C_Reads_Bytes(uint8_t device_addr, uint8_t reg_addr, uint8_t *data, uint16_t len);
uint8_t Soft_I2C_Writes_Byte(uint8_t device_addr, uint8_t reg_addr, uint8_t data);
uint8_t Soft_I2C_Reads_Byte(uint8_t device_addr, uint8_t reg_addr);

// 底层GPIO操作函数
void Soft_I2C_SCL_High(void);
void Soft_I2C_SCL_Low(void);
void Soft_I2C_SDA_High(void);
void Soft_I2C_SDA_Low(void);
uint8_t Soft_I2C_SDA_Read(void);
void Soft_I2C_Delay(void);

#endif
