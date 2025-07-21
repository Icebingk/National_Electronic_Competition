import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
import struct

# %% 低通FIR滤波器设计 - 使用窗函数法
# 清除之前的变量和图表
plt.close('all')

# %% 滤波器参数设定
fs = 40e6          # 采样频率: 40MHz (可根据需求调整)
data_width = 12    # 输入数据位宽
coeff_width = 32   # 系数量化位宽

# 滤波器设计规格
fc = 1e6           # 截止频率: 1MHz (可根据需求调整)
f_stop = 10e6      # 阻带起始频率: 10MHz (可根据需求调整)
pass_ripple = 0.1  # 通带纹波: 0.1dB
stop_atten = 40    # 阻带衰减: 40dB

# %% 使用窗函数法设计滤波器
# 计算归一化频率
norm_fc = fc / (fs/2)
dev_pass = 10**(pass_ripple/20)-1  # 通带纹波
dev_stop = 10**(-stop_atten/20)    # 阻带衰减

# 使用Kaiser窗估计所需的滤波器阶数
width = (f_stop - fc) / fs
n, beta = signal.kaiserord(stop_atten, width)

# 确保滤波器阶数为奇数(便于线性相位)
if n % 2 == 0:
    n += 1

# 设计滤波器 - 使用Kaiser窗
h = signal.firwin(n, norm_fc, window=('kaiser', beta))

print(f'滤波器阶数: {n}')
print(f'Kaiser窗参数beta: {beta:.4f}')

# %% 系数量化
# 直接量化到32位有符号定点数 (Q31格式)
# 不进行归一化，保持滤波器增益
scale_factor = 2**(coeff_width-1) - 1
h_quant = np.round(h * scale_factor) / scale_factor

# 检查是否有溢出
if np.any(np.abs(h_quant) >= 1):
    print('警告: 系数量化出现溢出，建议增加系数位宽或调整滤波器设计')

# %% 频率响应分析
w, H = signal.freqz(h, 1, 1024)
f = w * fs / (2 * np.pi)
w_quant, H_quant = signal.freqz(h_quant, 1, 1024)
f_quant = w_quant * fs / (2 * np.pi)

# 验证-3dB截止频率
fc_index = np.argmin(np.abs(f - fc))
fc_response_db = 20 * np.log10(np.abs(H[fc_index]))
print(f'在截止频率{fc/1e3:.0f}KHz处的响应: {fc_response_db:.2f}dB')

# 绘制频率响应
plt.figure(figsize=(10, 8))
plt.subplot(2, 1, 1)
plt.plot(f/1e6, 20 * np.log10(np.abs(H)), 'b-', 
         f_quant/1e6, 20 * np.log10(np.abs(H_quant)), 'r--')
plt.grid(True)
plt.title('滤波器频率响应')
plt.xlabel('频率 (MHz)')
plt.ylabel('幅度 (dB)')
plt.legend(['原始系数', '量化后系数'])
plt.xlim([0, 20])
plt.ylim([-100, 10])

plt.subplot(2, 1, 2)
plt.plot(f/1e6, 20 * np.log10(np.abs(H)), 'b-')
plt.grid(True)
plt.title('通带细节')
plt.xlabel('频率 (MHz)')
plt.ylabel('幅度 (dB)')
plt.xlim([0, 7])
plt.ylim([-3, 1])

# %% 生成系数文件
# 创建十六进制系数文件,生成coe文件
with open('coeff.coe', 'w') as fid_hex:
    fid_hex.write('MEMORY_INITIALIZATION_RADIX=16;\n')
    fid_hex.write('MEMORY_INITIALIZATION_VECTOR=\n')
    
    # 将量化后的系数转换为32位有符号整数
    h_int32 = np.int32(h_quant * scale_factor)
    
    for i in range(len(h_int32)):
        # 转换为十六进制表示
        # 先将int32转为uint32的二进制表示，再转为十六进制字符串
        hex_val = format(struct.unpack('<I', struct.pack('<i', h_int32[i]))[0], '08X')
        
        if i == len(h_int32) - 1:
            fid_hex.write(f'{hex_val};')
        else:
            fid_hex.write(f'{hex_val},\n')

print('系数文件 coeff.coe 生成完成。')

plt.tight_layout()
plt.show()