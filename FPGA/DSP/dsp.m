%% 低通FIR滤波器设计 - 使用窗函数法
clear;
close all;

%% 滤波器参数设定
fs = 125e6;         % 采样频率: 125MHz
data_width = 12;    % 输入数据位宽
coeff_width = 32;   % 系数量化位宽

% 滤波器设计规格
fc = 3e5;           % 截止频率: 300KHz (可根据需求调整)
f_stop = 10e6;       % 阻带起始频率: 10MHz (可根据需求调整)
pass_ripple = 0.1;  % 通带纹波: 0.1dB
stop_atten = 55;    % 阻带衰减: 55dB

%% 使用窗函数法设计滤波器
% 计算归一化频率
norm_fc = fc / (fs/2);
dev_pass = 10^(pass_ripple/20)-1; % 通带纹波
dev_stop = 10^(-stop_atten/20); % 阻带衰减
% 使用Kaiser窗估计所需的滤波器阶数
[n, wn, beta, ftype] = kaiserord([fc f_stop], [1 0], [dev_pass dev_stop], fs);

% 确保滤波器阶数为奇数(便于线性相位)
if mod(n, 2) == 0
    n = n + 1;
end

% 设计滤波器 - 使用Kaiser窗
h = fir1(n, norm_fc, 'low', kaiser(n+1, beta));

fprintf('滤波器阶数: %d\n', n);
fprintf('Kaiser窗参数beta: %.4f\n', beta);

%% 系数量化
% 系数归一化
h_norm = h / max(abs(h));  

% 量化到32位 (保留符号位)
scale_factor = 2^(coeff_width-1) - 1;
h_quant = round(h_norm * scale_factor) / scale_factor;

%% 频率响应分析
[H, f] = freqz(h, 1, 1024, fs);
[H_quant, f_quant] = freqz(h_quant, 1, 1024, fs);

% 绘制频率响应
figure;
subplot(2,1,1);
plot(f/1e6, 20*log10(abs(H)), 'b-', f_quant/1e6, 20*log10(abs(H_quant)), 'r--');
grid on;
title('滤波器频率响应');
xlabel('频率 (MHz)');
ylabel('幅度 (dB)');
legend('原始系数', '量化后系数');
xlim([0 20]);
ylim([-100 10]);

subplot(2,1,2);
plot(f/1e6, 20*log10(abs(H)), 'b-');
grid on;
title('通带细节');
xlabel('频率 (MHz)');
ylabel('幅度 (dB)');
xlim([0 7]);
ylim([-3 1]);

%% 生成系数文件
% 创建十六进制系数文件,生成coe文件
fid_hex = fopen('coeff.coe', 'w');
fprintf(fid_hex, 'MEMORY_INITIALIZATION_RADIX=16;\n');
fprintf(fid_hex, 'MEMORY_INITIALIZATION_VECTOR=\n');
for i = 1:length(h_quant)
    if i == length(h_quant)
        fprintf(fid_hex, '%08X;', typecast(single(h_quant(i)), 'uint32'));
    else
        fprintf(fid_hex, '%08X,\n', typecast(single(h_quant(i)), 'uint32'));
    end
end
fclose(fid_hex);

fprintf('系数文件 coeff.coe 生成完成。\n');