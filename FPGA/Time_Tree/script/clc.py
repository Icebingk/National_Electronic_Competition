# -*- coding: utf-8 -*-
import math

def find_best_params(target_freq, clk_in=50.0):
    """
    计算最接近目标频率的倍频和分频参数。
    :param target_freq: 目标频率 (MHz)
    :param clk_in: 输入时钟频率 (MHz)
    :return: (整数倍频, 小数倍频, 一级整数分频, 二级整数分频, 二级小数分频)
    """
    frac_unit = 0.125
    best = None
    min_err = float('inf')
    # 预先生成所有可能的小数部分，避免重复计算
    frac_list = [round(i * frac_unit, 3) for i in range(0, 8)]
    for mult_int in range(1, 50):  # 适当减小上限，加速
        for mult_frac in frac_list:
            mult = mult_int + mult_frac
            for div1 in range(1, 5):
                for div2 in range(1, 15):  # 适当减小上限，加速
                    for div_frac in frac_list:
                        div = div2 + div_frac
                        freq = clk_in * mult / div1 / div
                        err = abs(freq - target_freq)
                        if err < min_err:
                            min_err = err
                            best = (
                                mult_int,
                                mult_frac,
                                div1,
                                div2,
                                div_frac
                            )
                            if min_err < 1e-6:
                                return best  # 直接返回，极大加速
    return best

def format_params(freq, params):
    """
    按指定格式输出参数
    """
    mult_int, mult_frac, div1, div2, div_frac = params
    return f"""{freq}:
frq_mult_int = {mult_int}
frq_mult_float = {mult_frac}
frq_div_int_all = {div1}
frq_div_int = {div2}
frq_div_float = {div_frac}
"""

if __name__ == "__main__":
    # 目标频率列表，可自行修改
    target_freqs = [88, 88.1, 88.2, 88.3, 88.4, 88.5, 88.6, 88.7, 88.8, 88.9, 89,
                        89.1, 89.2, 89.3, 89.4, 89.5, 89.6, 89.7, 89.8, 89.9, 90,
                        90.1, 90.2, 90.3, 90.4, 90.5, 90.6, 90.7, 90.8, 90.9, 91,
                        91.1, 91.2, 91.3, 91.4, 91.5, 91.6, 91.7, 91.8, 91.9, 92,
                        92.1, 92.2, 92.3, 92.4, 92.5, 92.6, 92.7, 92.8, 92.9, 93,
                        93.1, 93.2, 93.3, 93.4, 93.5, 93.6, 93.7, 93.8, 93.9, 94,
                        94.1, 94.2, 94.3, 94.4, 94.5, 94.6, 94.7, 94.8, 94.9, 95,
                        95.1, 95.2, 95.3, 95.4, 95.5, 95.6, 95.7, 95.8, 95.9, 96,
                        96.1, 96.2, 96.3, 96.4, 96.5, 96.6, 96.7, 96.8, 96.9, 97,
                        97.1, 97.2, 97.3, 97.4, 97.5, 97.6, 97.7, 97.8, 97.9, 98,
                        98.1, 98.2, 98.3, 98.4, 98.5, 98.6, 98.7, 98.8, 98.9, 99,
                        99.1, 99.2, 99.3, 99.4, 99.5, 99.6, 99.7, 99.8, 99.9, 100,
                        100.1, 100.2, 100.3, 100.4, 100.5, 100.6, 100.7, 100.8, 100.9, 101,
                        101.1, 101.2, 101.3, 101.4, 101.5, 101.6, 101.7, 101.8, 101.9, 102,
                        102.1, 102.2, 102.3, 102.4, 102.5, 102.6, 102.7, 102.8, 102.9, 103,
                        103.1, 103.2, 103.3, 103.4, 103.5, 103.6, 103.7, 103.8, 103.9, 104,
                        104.1, 104.2, 104.3, 104.4, 104.5, 104.6, 104.7, 104.8, 104.9, 105,
                        105.1, 105.2, 105.3, 105.4, 105.5, 105.6, 105.7, 105.8, 105.9, 106,
                        106.1, 106.2, 106.3, 106.4, 106.5, 106.6, 106.7, 106.8, 106.9, 107,
                        107.1, 107.2, 107.3, 107.4, 107.5, 107.6, 107.7, 107.8, 107.9, 108]
    with open("freq_params.txt", "w", encoding="utf-8") as f:
        for freq in target_freqs:
            params = find_best_params(freq)
            f.write(format_params(freq, params))