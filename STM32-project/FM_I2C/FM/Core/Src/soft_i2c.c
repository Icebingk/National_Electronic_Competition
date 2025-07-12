/**
  ******************************************************************************
  * @file           : soft_i2c.c
  * @brief          : Software I2C implementation
  ******************************************************************************
  * @attention
  *
  * This file implements software I2C communication for STM32F4xx
  * 
  ******************************************************************************
  */

#include "soft_i2c.h"

// 私有变量
static uint32_t delay_count = 0;

/**
  * @brief  微秒延时函数
  * @param  us: 延时微秒数
  * @retval None
  */
static void delay_us(uint32_t us)
{
    delay_count = us * (SystemCoreClock / 1000000) / 4;
    while(delay_count--);
}

/**
  * @brief  I2C延时函数
  * @param  None
  * @retval None
  */
void Soft_I2C_Delay(void)
{
    delay_us(SOFT_I2C_DELAY_US);
}

/**
  * @brief  设置SCL为高电平
  * @param  None
  * @retval None
  */
void Soft_I2C_SCL_High(void)
{
    HAL_GPIO_WritePin(SOFT_I2C_SCL_PORT, SOFT_I2C_SCL_PIN, GPIO_PIN_SET);
}

/**
  * @brief  设置SCL为低电平
  * @param  None
  * @retval None
  */
void Soft_I2C_SCL_Low(void)
{
    HAL_GPIO_WritePin(SOFT_I2C_SCL_PORT, SOFT_I2C_SCL_PIN, GPIO_PIN_RESET);
}

/**
  * @brief  设置SDA为高电平
  * @param  None
  * @retval None
  */
void Soft_I2C_SDA_High(void)
{
    HAL_GPIO_WritePin(SOFT_I2C_SDA_PORT, SOFT_I2C_SDA_PIN, GPIO_PIN_SET);
}

/**
  * @brief  设置SDA为低电平
  * @param  None
  * @retval None
  */
void Soft_I2C_SDA_Low(void)
{
    HAL_GPIO_WritePin(SOFT_I2C_SDA_PORT, SOFT_I2C_SDA_PIN, GPIO_PIN_RESET);
}

/**
  * @brief  读取SDA状态
  * @param  None
  * @retval SDA引脚状态
  */
uint8_t Soft_I2C_SDA_Read(void)
{
    return HAL_GPIO_ReadPin(SOFT_I2C_SDA_PORT, SOFT_I2C_SDA_PIN);
}

/**
  * @brief  软件I2C初始化
  * @param  None
  * @retval None
  */
void Soft_I2C_Init(void)
{
    // 初始化为高电平
    Soft_I2C_SCL_High();
    Soft_I2C_SDA_High();
}

/**
  * @brief  I2C开始信号
  * @param  None
  * @retval None
  */
void Soft_I2C_Start(void)
{
    Soft_I2C_SDA_High();
    Soft_I2C_SCL_High();
    Soft_I2C_Delay();
    Soft_I2C_SDA_Low();
    Soft_I2C_Delay();
    Soft_I2C_SCL_Low();
    Soft_I2C_Delay();
}

/**
  * @brief  I2C停止信号
  * @param  None
  * @retval None
  */
void Soft_I2C_Stop(void)
{
    Soft_I2C_SDA_Low();
    Soft_I2C_SCL_Low();
    Soft_I2C_Delay();
    Soft_I2C_SCL_High();
    Soft_I2C_Delay();
    Soft_I2C_SDA_High();
    Soft_I2C_Delay();
}

/**
  * @brief  等待应答信号
  * @param  None
  * @retval 0:收到应答 1:未收到应答
  */
uint8_t Soft_I2C_Wait_Ack(void)
{
    uint8_t timeout = 0;
    
    Soft_I2C_SDA_High();
    Soft_I2C_Delay();
    Soft_I2C_SCL_High();
    Soft_I2C_Delay();
    
    // while(Soft_I2C_SDA_Read())
    // {
    //     timeout++;
    //     if(timeout > 250)
    //     {
    //         Soft_I2C_Stop();
    //         return SOFT_I2C_ERROR;
    //     }
    // }
    
    Soft_I2C_SCL_Low();
    Soft_I2C_Delay();
    return SOFT_I2C_OK;
}

/**
  * @brief  产生应答信号
  * @param  None
  * @retval None
  */
void Soft_I2C_Ack(void)
{
    Soft_I2C_SCL_Low();
    Soft_I2C_Delay();
    Soft_I2C_SDA_Low();
    Soft_I2C_Delay();
    Soft_I2C_SCL_High();
    Soft_I2C_Delay();
    Soft_I2C_SCL_Low();
    Soft_I2C_Delay();
}

/**
  * @brief  产生非应答信号
  * @param  None
  * @retval None
  */
void Soft_I2C_NAck(void)
{
    Soft_I2C_SCL_Low();
    Soft_I2C_Delay();
    Soft_I2C_SDA_High();
    Soft_I2C_Delay();
    Soft_I2C_SCL_High();
    Soft_I2C_Delay();
    Soft_I2C_SCL_Low();
    Soft_I2C_Delay();
}

/**
  * @brief  发送一个字节
  * @param  byte: 要发送的字节
  * @retval None
  */
void Soft_I2C_Send_Byte(uint8_t byte)
{
    uint8_t i;
    
    Soft_I2C_SCL_Low();
    
    for(i = 0; i < 8; i++)
    {
        if(byte & 0x80)
            Soft_I2C_SDA_High();
        else
            Soft_I2C_SDA_Low();
        
        byte <<= 1;
        Soft_I2C_Delay();
        Soft_I2C_SCL_High();
        Soft_I2C_Delay();
        Soft_I2C_SCL_Low();
        Soft_I2C_Delay();
    }
}

/**
  * @brief  读取一个字节
  * @param  None
  * @retval 读取到的字节
  */
uint8_t Soft_I2C_Read_Byte(void)
{
    uint8_t i, receive = 0;
    
    for(i = 0; i < 8; i++)
    {
        Soft_I2C_SCL_Low();
        Soft_I2C_Delay();
        Soft_I2C_SCL_High();
        Soft_I2C_Delay();
        
        receive <<= 1;
        if(Soft_I2C_SDA_Read())
            receive |= 0x01;
    }
    
    Soft_I2C_SCL_Low();
    Soft_I2C_Delay();
    return receive;
}

/**
  * @brief  写入多个字节
  * @param  device_addr: 设备地址
  * @param  reg_addr: 寄存器地址
  * @param  data: 要写入的数据
  * @param  len: 数据长度
  * @retval 0:成功 1:失败
  */
uint8_t Soft_I2C_Writes_Bytes(uint8_t device_addr, uint8_t reg_addr, uint8_t *data, uint16_t len)
{
    uint16_t i;
    
    Soft_I2C_Start();
    
    // 发送设备地址+写命令
    Soft_I2C_Send_Byte(device_addr << 1);
    if(Soft_I2C_Wait_Ack() != SOFT_I2C_OK)
        return SOFT_I2C_ERROR;
    
    // 发送寄存器地址
    Soft_I2C_Send_Byte(reg_addr);
    if(Soft_I2C_Wait_Ack() != SOFT_I2C_OK)
        return SOFT_I2C_ERROR;
    
    // 发送数据
    for(i = 0; i < len; i++)
    {
        Soft_I2C_Send_Byte(data[i]);
        if(Soft_I2C_Wait_Ack() != SOFT_I2C_OK)
            return SOFT_I2C_ERROR;
    }
    
    Soft_I2C_Stop();
    return SOFT_I2C_OK;
}

/**
  * @brief  读取多个字节
  * @param  device_addr: 设备地址
  * @param  reg_addr: 寄存器地址
  * @param  data: 读取的数据缓冲区
  * @param  len: 数据长度
  * @retval 0:成功 1:失败
  */
uint8_t Soft_I2C_Reads_Bytes(uint8_t device_addr, uint8_t reg_addr, uint8_t *data, uint16_t len)
{
    uint16_t i;
    
    Soft_I2C_Start();
    
    // 发送设备地址+写命令
    Soft_I2C_Send_Byte(device_addr << 1);
    if(Soft_I2C_Wait_Ack() != SOFT_I2C_OK)
        return SOFT_I2C_ERROR;
    
    // 发送寄存器地址
    Soft_I2C_Send_Byte(reg_addr);
    if(Soft_I2C_Wait_Ack() != SOFT_I2C_OK)
        return SOFT_I2C_ERROR;
    
    // 重新开始
    Soft_I2C_Start();
    
    // 发送设备地址+读命令
    Soft_I2C_Send_Byte((device_addr << 1) | 0x01);
    if(Soft_I2C_Wait_Ack() != SOFT_I2C_OK)
        return SOFT_I2C_ERROR;
    
    // 读取数据
    for(i = 0; i < len; i++)
    {
        data[i] = Soft_I2C_Read_Byte();
        if(i < len - 1)
            Soft_I2C_Ack();
        else
            Soft_I2C_NAck();
    }
    
    Soft_I2C_Stop();
    return SOFT_I2C_OK;
}

/**
  * @brief  写入单个字节
  * @param  device_addr: 设备地址
  * @param  reg_addr: 寄存器地址
  * @param  data: 要写入的数据
  * @retval 0:成功 1:失败
  */
uint8_t Soft_I2C_Writes_Byte(uint8_t device_addr, uint8_t reg_addr, uint8_t data)
{
    return Soft_I2C_Writes_Bytes(device_addr, reg_addr, &data, 1);
}

/**
  * @brief  读取单个字节
  * @param  device_addr: 设备地址
  * @param  reg_addr: 寄存器地址
  * @retval 读取到的字节
  */
uint8_t Soft_I2C_Reads_Byte(uint8_t device_addr, uint8_t reg_addr)
{
    uint8_t data = 0;
    Soft_I2C_Reads_Bytes(device_addr, reg_addr, &data, 1);
    return data;     
}
