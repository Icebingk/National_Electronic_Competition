"""
DDS双波形频率参数计算工具
用于计算FPGA DDS设计中的双路波形频率控制字和相关参数
支持MHz级主波形和kHz级辅助波形的同时计算
支持不同时钟频率下的计算和Verilog代码生成
"""
import sys
from math import pow
from typing import Dict, Any, Union, Optional

def calculate_dds_params(sys_clock: float, target_freq: float, phase_bits: int = 32) -> Dict[str, Any]:
    """
    计算DDS关键参数
    
    参数:
        sys_clock: 系统时钟频率(Hz)
        target_freq: 目标输出频率(Hz)
        phase_bits: 相位累加器位宽(默认32位)
        
    返回:
        包含以下键的字典:
        - fcw: 频率控制字(整数)
        - actual_freq: 实际输出频率(Hz)
        - freq_resolution: 频率分辨率(Hz)
        - freq_error: 频率误差(Hz)
        - error_ppm: 百万分比误差(ppm)
    """
    # 计算频率控制字
    fcw = int((target_freq * (2**phase_bits)) / sys_clock)
    
    # 计算实际输出频率(考虑量化误差)
    actual_freq = (fcw * sys_clock) / (2**phase_bits)
    
    # 计算频率分辨率
    freq_resolution = sys_clock / (2**phase_bits)
    
    # 计算误差
    freq_error = actual_freq - target_freq
    error_ppm = (freq_error / target_freq) * 1_000_000 if target_freq != 0 else 0
    
    return {
        'fcw': fcw,
        'actual_freq': actual_freq,
        'freq_resolution': freq_resolution,
        'freq_error': freq_error,
        'error_ppm': error_ppm
    }

def format_verilog(value: int) -> str:
    """将整数格式化为Verilog参数格式"""
    return f"32'd{value}"

def format_verilog_define(name: str, value: int, comment: str = "") -> str:
    """生成完整的Verilog `define语句"""
    return f"`define {name} {format_verilog(value)}{' // ' + comment if comment else ''}"

def print_result(params: Dict[str, Any], sys_clock: float, target_freq: float, is_khz: bool = False) -> None:
    """漂亮地打印计算结果"""
    print("\n" + "="*50)
    if is_khz:
        print(f"【DDS参数计算结果 - 第二路(kHz级)波形】")
    else:
        print(f"【DDS参数计算结果 - 第一路(MHz级)波形】")
    print("="*50)
    print(f"系统时钟:     {sys_clock/1_000_000:.4f} MHz")
    
    if is_khz:
        print(f"目标频率:     {target_freq/1_000:.6f} kHz")
        print(f"实际输出频率: {params['actual_freq']/1_000:.6f} kHz")
    else:
        print(f"目标频率:     {target_freq/1_000_000:.6f} MHz")
        print(f"实际输出频率: {params['actual_freq']/1_000_000:.6f} MHz")
    
    print(f"频率控制字:   {params['fcw']} ({format_verilog(params['fcw'])})")
    print(f"频率分辨率:   {params['freq_resolution']:.4f} Hz")
    print(f"频率误差:     {params['freq_error']:.4f} Hz ({params['error_ppm']:.4f} ppm)")
    print("="*50)

def interactive_mode() -> None:
    """交互式计算模式"""
    print("\n" + "="*60)
    print("     DDS双波形频率参数计算工具 v3.0")
    print("     支持MHz级主波形和kHz级辅助波形的同时计算")
    print("     用于FPGA双路DDS设计的频率控制参数计算")
    print("="*60)
    
    while True:
        try:
            print("\n-- 请输入参数 (输入q退出) --")
            clock_input = input("系统时钟频率 (MHz): ")
            if clock_input.lower() in ('q', 'quit', 'exit'):
                print("\n感谢使用，再见！")
                break
                
            sys_clock = float(clock_input) * 1_000_000
            
            # 可选的相位位宽
            phase_bits_input = input("相位累加器位宽 [32]: ")
            phase_bits = 32 if not phase_bits_input else int(phase_bits_input)
            
            # ===================== 第一路波形 (MHz级) =====================
            print("\n--- 第一路波形参数 (MHz级) ---")
            
            target_input = input("目标输出频率 (MHz): ")
            if target_input.lower() in ('q', 'quit', 'exit'):
                print("\n感谢使用，再见！")
                break
                
            target_freq = float(target_input) * 1_000_000
            
            # 计算基本参数
            params = calculate_dds_params(sys_clock, target_freq, phase_bits)
            print_result(params, sys_clock, target_freq)
            
            # 计算步进值
            step_input = input("频率步进值 (MHz, 直接回车跳过): ")
            step_params = None
            if step_input and step_input.lower() not in ('q', 'quit', 'exit'):
                step_freq = float(step_input) * 1_000_000
                step_params = calculate_dds_params(sys_clock, step_freq, phase_bits)
                print(f"\n步进控制字: {step_params['fcw']} ({format_verilog(step_params['fcw'])})")
            
            # 频率最大限制
            max_input = input("频率最大值 (MHz, 直接回车跳过): ")
            max_params = None
            if max_input and max_input.lower() not in ('q', 'quit', 'exit'):
                max_freq = float(max_input) * 1_000_000
                max_params = calculate_dds_params(sys_clock, max_freq, phase_bits)
            
            # ===================== 第二路波形 (kHz级) =====================
            print("\n--- 第二路波形参数 (kHz级) ---")
            
            target_input2 = input("目标输出频率 (kHz): ")
            if target_input2.lower() in ('q', 'quit', 'exit'):
                print("\n感谢使用，再见！")
                break
            
            if not target_input2:
                have_second_wave = False
            else:
                have_second_wave = True
                target_freq2 = float(target_input2) * 1_000  # 转换为Hz
                
                # 计算第二路波形基本参数
                params2 = calculate_dds_params(sys_clock, target_freq2, phase_bits)
                print_result(params2, sys_clock, target_freq2, is_khz=True)
                
                # 计算第二路步进值
                step_input2 = input("频率步进值 (kHz, 直接回车跳过): ")
                step_params2 = None
                if step_input2 and step_input2.lower() not in ('q', 'quit', 'exit'):
                    step_freq2 = float(step_input2) * 1_000
                    step_params2 = calculate_dds_params(sys_clock, step_freq2, phase_bits)
                    print(f"\n步进控制字: {step_params2['fcw']} ({format_verilog(step_params2['fcw'])})")
                
                # 第二路频率最大限制
                max_input2 = input("频率最大值 (kHz, 直接回车跳过): ")
                max_params2 = None
                if max_input2 and max_input2.lower() not in ('q', 'quit', 'exit'):
                    max_freq2 = float(max_input2) * 1_000
                    max_params2 = calculate_dds_params(sys_clock, max_freq2, phase_bits)
            
            # 生成Verilog代码
            print("\n-- Verilog定义代码 --")
            
            # 第一路波形定义
            print("\n// 第一路波形 (MHz级)")
            print(f"`define FREQ_CTRL_1_MHZ {format_verilog(params['fcw'])} " + 
                  f"// {target_freq/1_000_000:.2f}MHz@{sys_clock/1_000_000:.2f}MHz时钟")
            
            if step_params:
                print(f"`define FREQ_STEP_1_MHZ {format_verilog(step_params['fcw'])}  " + 
                      f"// {step_freq/1_000_000:.2f}MHz步进@{sys_clock/1_000_000:.2f}MHz时钟")

            if max_params:
                print(f"`define FREQ_MAX_1_LIMIT {format_verilog(max_params['fcw'])} " + 
                      f"// {max_freq/1_000_000:.2f}MHz最大值")
            
            # 第二路波形定义（如果有）
            if have_second_wave:
                print("\n// 第二路波形 (kHz级)")
                print(f"`define FREQ_CTRL_2_KHZ {format_verilog(params2['fcw'])} " + 
                      f"// {target_freq2/1_000:.2f}kHz@{sys_clock/1_000_000:.2f}MHz时钟")
                
                if step_params2:
                    print(f"`define FREQ_STEP_2_KHZ {format_verilog(step_params2['fcw'])}  " + 
                          f"// {step_freq2/1_000:.2f}kHz步进@{sys_clock/1_000_000:.2f}MHz时钟")
    
                if max_params2:
                    print(f"`define FREQ_MAX_2_LIMIT {format_verilog(max_params2['fcw'])} " + 
                          f"// {max_freq2/1_000:.2f}kHz最大值")
                
        except ValueError as e:
            print(f"输入错误: 请确保输入有效的数字! ({e})")
        except Exception as e:
            print(f"处理出错: {e}")
            
def main():125
    """主函数"""
    if len(sys.argv) > 1 and sys.argv[1].lower() in ('-h', '--help'):
        print(__doc__)
        print("\n用法: python clc.py")
        return
        
    interactive_mode()

if __name__ == "__main__":
    main()