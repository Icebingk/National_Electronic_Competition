import numpy as np
import os

# 14位DAC正弦波LUT，16位地址深度
DAC_BITS = 14
CENTER = 2**(DAC_BITS-1)      # 8192
AMPLITUDE = CENTER - 1        # 8191
ADDR_BITS = 12                # 13位地址
ADDR_DEPTH = 2**ADDR_BITS     

# 获取当前脚本所在文件夹
current_dir = os.path.dirname(os.path.abspath(__file__))
output_file = os.path.join(current_dir, "sine_lut_14bit.coe")

with open(output_file, "w") as f:
    # 使用十进制基数，这与实际写入的数值类型匹配
    f.write("memory_initialization_radix=10;\n")
    f.write("memory_initialization_vector=\n")
    
    # 生成2^16个点的正弦波
    for i in range(ADDR_DEPTH):
        # 计算正弦值并缩放到14位范围
        val = int(CENTER + AMPLITUDE * np.sin(2 * np.pi * i / ADDR_DEPTH))
        
        # 最后一个点用分号结尾，其他用逗号
        ending = ';' if i == ADDR_DEPTH - 1 else ','
        
        # 写入当前值
        f.write(f"{val}{ending}\n")
        
        # 每10000个点显示一次进度
        if i % 10000 == 0:
            print(f"生成进度: {i}/{ADDR_DEPTH} ({i/ADDR_DEPTH*100:.1f}%)")
    
print(f"已生成{ADDR_DEPTH}点(16位地址)正弦波LUT文件: {output_file}")