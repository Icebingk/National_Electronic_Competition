#include "Power.h"

// 0V对应-80dBm，斜率是25MV/dB

void Power_clc_Voltage(float voltage /* mV */ ) {
    // Implementation for Power_clc_Voltage
    float power = (voltage + 80) / 25;
}

void Voltage_clc_Power(float power /* dBm */ ) {
    // Implementation for Voltage_clc_Power
    float voltage = power * 25 - 80;
}