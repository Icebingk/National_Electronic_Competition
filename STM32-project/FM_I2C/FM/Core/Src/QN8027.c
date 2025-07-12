#include "QN8027.h"

#define  QN8027_I2C_ADD (0x2C << 1)  // QN8027 I2C地址，7位地址0x2C左移1位

// 接收数据
void QN8027I2CRead(uint8_t* Data, uint8_t length){
	HAL_I2C_Master_Receive(&hi2c1, QN8027_I2C_ADD, Data, length, 100);
}	
// 发送数据
void QN8027I2CWrite(uint8_t* Data, uint8_t length){
	HAL_I2C_Master_Transmit(&hi2c1, QN8027_I2C_ADD, Data, length, 100);
}

// 单次写寄存器
void QN8027WriteReg(uint8_t Addr, uint8_t data){
	uint8_t arr[2];
	arr[0] = Addr;
	arr[1] = data;
	QN8027I2CWrite(arr,2);
}
// 单次读寄存器
void QN8027ReadReg(uint8_t Addr, uint8_t* data){
	QN8027I2CWrite(&Addr,1);
	QN8027I2CRead(data,1);
}

// 连续读寄存器
void QN8027ReadRegisterDim(uint8_t Address, uint8_t* Reg, uint8_t Number){
  QN8027I2CWrite(&Address, 1);
  QN8027I2CRead(Reg, Number); 
}
// 连续写寄存器
void QN8027WriteRegisterDim(uint8_t Address, uint8_t* Reg, uint8_t Number){
  uint8_t buffer[Number + 1];  // 创建缓冲区，包含地址和数据
  buffer[0] = Address;         // 第一个字节是寄存器地址
  for(uint8_t i = 0; i < Number; i++){
    buffer[i + 1] = Reg[i];    // 复制数据到缓冲区
  }
  QN8027I2CWrite(buffer, Number + 1);  // 一次性发送地址和数据
}

// 读取所有寄存器内容
void QN8027ReadAllRegisters(uint8_t* Reg){
  QN8027I2CWrite(0x00, 1); 	   // 发送寄存器地址
  QN8027I2CRead(Reg,19);       // 读取所有寄存器内容
}

// 修改输出频率，但是不会启动发射
void QN8027SetOutputFrequency(float frq_MHz){
	uint32_t Frq = (uint8_t)(frq_MHz - 76) * 20; // 将频率转换为寄存器值
	uint8_t uc00 = (uint8_t)(Frq >> 8) & 0x03;
	uint8_t uc01 = (uint8_t)(Frq & 0xFF);

	uint8_t ucarr[2]; // 设置寄存器值
	ucarr[0] = uc00; // 寄存器地址
	ucarr[1] = uc01; // 寄存器值高字节
	QN8027WriteRegisterDim(0x00,ucarr, 2); // 写入寄存器
}

// 初始化QN8027寄存器
void QN8027Initialize() {
	// 初始化QN8027寄存器
	//1. 软复位(00h)
	uint8_t initData[2] = {0x00, 0x80}; // 根据需要设置初始值
	QN8027WriteReg(0x00, initData[1]); // 写入软复位命令
	HAL_Delay(20); // 等待软复位完成
	QN8027WriteReg(0x00, initData[0]); // `

	//2. 设置输出频率(01h)
	QN8027SetOutputFrequency(87.5f); // 设置初始输出频率为87.5MHz

	//3. 音频设置(02h)
	QN8027WriteReg(0x02, 0xA9); // 设置音频寄存器

	//4. 输入增益(04h)
	QN8027WriteReg(0x04, 0x32); // 设置音频寄存器

	//5. PA功率 (10h)
	QN8027WriteReg(0x10, 0x32); // 设置PA功率寄存器

	//6. 禁用RDS（12h）
	QN8027WriteReg(0x12, 0x00); // 禁用RDS功能

	//7. 启动发射（00h）
	uint8_t reg00_current;
	QN8027ReadReg(0x00, &reg00_current);		// 读取当前00h寄存器值
	QN8027WriteReg(0x00, reg00_current | 0x20); // 设置发射位，保持频率设置
}
