set_property PACKAGE_PIN R4 [get_ports clk_in]
set_property PACKAGE_PIN T3 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports clk_in]

set_property PACKAGE_PIN H14 [get_ports clk_dac]
set_property IOSTANDARD LVCMOS33 [get_ports clk_dac]

set_property PACKAGE_PIN H15 [get_ports {dac_data[12]}]
set_property PACKAGE_PIN G16 [get_ports {dac_data[10]}]
set_property PACKAGE_PIN G18 [get_ports {dac_data[8]}]
set_property PACKAGE_PIN H18 [get_ports {dac_data[6]}]
set_property PACKAGE_PIN H19 [get_ports {dac_data[4]}]
set_property PACKAGE_PIN G20 [get_ports {dac_data[2]}]
set_property PACKAGE_PIN J21 [get_ports {dac_data[0]}]

set_property PACKAGE_PIN J15 [get_ports {dac_data[13]}]
set_property PACKAGE_PIN G15 [get_ports {dac_data[11]}]
set_property PACKAGE_PIN G17 [get_ports {dac_data[9]}]
set_property PACKAGE_PIN H17 [get_ports {dac_data[7]}]
set_property PACKAGE_PIN J19 [get_ports {dac_data[5]}]
set_property PACKAGE_PIN H20 [get_ports {dac_data[3]}]
set_property PACKAGE_PIN J20 [get_ports {dac_data[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {dac_data[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac_data[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac_data[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac_data[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {dac_data[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac_data[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac_data[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac_data[1]}]

# ADC连线和电平标准
set_property PACKAGE_PIN N22 [get_ports clk_adc]
set_property IOSTANDARD LVCMOS33 [get_ports clk_adc]

set_property PACKAGE_PIN N20 [get_ports {adc_data[10]}]
set_property PACKAGE_PIN L19 [get_ports {adc_data[8]}]
set_property PACKAGE_PIN N18 [get_ports {adc_data[6]}]
set_property PACKAGE_PIN K18 [get_ports {adc_data[4]}]
set_property PACKAGE_PIN M18 [get_ports {adc_data[2]}]
set_property PACKAGE_PIN M15 [get_ports {adc_data[0]}]

set_property PACKAGE_PIN M22 [get_ports {adc_data[11]}]
set_property PACKAGE_PIN M20 [get_ports {adc_data[9]}]
set_property PACKAGE_PIN L20 [get_ports {adc_data[7]}]
set_property PACKAGE_PIN N19 [get_ports {adc_data[5]}]
set_property PACKAGE_PIN K19 [get_ports {adc_data[3]}]
set_property PACKAGE_PIN L18 [get_ports {adc_data[1]}]
set_property PACKAGE_PIN M16 [get_ports OTR]

set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports OTR]

set_false_path -from [get_ports rst_n]

set_false_path -from [get_ports {adc_data[10]}]
set_false_path -from [get_ports {adc_data[8]}]
set_false_path -from [get_ports {adc_data[6]}]
set_false_path -from [get_ports {adc_data[4]}]
set_false_path -from [get_ports {adc_data[2]}]
set_false_path -from [get_ports {adc_data[0]}]
set_false_path -from [get_ports {adc_data[11]}]
set_false_path -from [get_ports {adc_data[9]}]
set_false_path -from [get_ports {adc_data[7]}]
set_false_path -from [get_ports {adc_data[5]}]
set_false_path -from [get_ports {adc_data[3]}]
set_false_path -from [get_ports {adc_data[1]}]
set_false_path -from [get_ports OTR]

# 生成时钟约束 - ADC时钟 (60MHz)
create_generated_clock -name clk_adc -source [get_ports clk_in] -multiply_by 6 -divide_by 5 [get_ports clk_adc]

# 生成时钟约束 - FIR处理时钟 (200MHz)
# create_generated_clock -name sys_clk -source [get_ports clk_in] -multiply_by 4 -divide_by 1 [get_nets  sys_clk]

# 生成时钟约束 - DAC时钟 (120MHz)
create_generated_clock -name clk_dac -source [get_ports clk_in] -multiply_by 12 -divide_by 5 [get_ports clk_dac]

# 输入延迟约束 (针对60MHz ADC时钟)
set_input_delay -clock [get_clocks clk_adc] -min 2.000 [get_ports {adc_data[*]}]
set_input_delay -clock [get_clocks clk_adc] -max 8.000 [get_ports {adc_data[*]}]
set_input_delay -clock [get_clocks clk_adc] -min 2.000 [get_ports OTR]
set_input_delay -clock [get_clocks clk_adc] -max 8.000 [get_ports OTR]

# 输出延迟约束 (针对100MHz DAC时钟)
set_output_delay -clock [get_clocks clk_dac] -min 2.000 [get_ports {dac_data[*]}]
set_output_delay -clock [get_clocks clk_dac] -max 5.000 [get_ports {dac_data[*]}]