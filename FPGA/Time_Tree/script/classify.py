import os

# 读取新格式的参数文件
with open(r"e:\NEC\freq_params.txt", encoding="utf-8") as f:
    lines = [line.strip() for line in f if line.strip()]

freqs = []
frq_mult_ints = []
frq_mult_floats = []
frq_div_int_alls = []
frq_div_ints = []
frq_div_floats = []

for i in range(0, len(lines), 6):
    freqs.append(lines[i].replace(":", ""))
    frq_mult_ints.append(lines[i+1].split("=")[-1].strip())
    frq_mult_floats.append(lines[i+2].split("=")[-1].strip())
    frq_div_int_alls.append(lines[i+3].split("=")[-1].strip())
    frq_div_ints.append(lines[i+4].split("=")[-1].strip())
    frq_div_floats.append(lines[i+5].split("=")[-1].strip())

print(f"实际读取到的频率数量: {len(freqs)}")

base_dir = r"e:\NEC"

def write_vec_file(filename, values):
    with open(os.path.join(base_dir, filename), "w", encoding="utf-8") as f:
        f.write("MEMORY_INITIALIZATION_RADIX=10;\nMEMORY_INITIALIZATION_VECTOR=\n")
        for idx, val in enumerate(values):
            end = ";\n" if idx == len(values) - 1 else ",\n"
            f.write(f"{val}{end}")

write_vec_file("frq_mult_int.coe", frq_mult_ints)
write_vec_file("frq_mult_float.coe", [int(float(val)*1000) for val in frq_mult_floats])
write_vec_file("frq_div_int_all.coe", frq_div_int_alls)
write_vec_file("frq_div_int.coe", frq_div_ints)
write_vec_file("frq_div_float.coe", [int(float(val)*1000) for val in frq_div_floats])

print("已按类别分别保存到5个coe文件。")