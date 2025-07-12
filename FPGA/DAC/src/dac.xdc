set_property PACKAGE_PIN R4 [get_ports sys_clk]
set_property PACKAGE_PIN T3 [get_ports rst_n]
set_property PACKAGE_PIN C14 [get_ports clk_adc]
set_property IOSTANDARD LVCMOS33 [get_ports clk_adc]
set_property IOSTANDARD LVCMOS33 [get_ports clk_dac]
set_property IOSTANDARD LVCMOS33 [get_ports clk_fir]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports valid]

set_property IOSTANDARD LVCMOS33 [get_ports ligtht]

set_property PACKAGE_PIN B17 [get_ports clk_dac]
set_property PACKAGE_PIN B21 [get_ports valid]

set_property PACKAGE_PIN E16 [get_ports clk_fir]
set_property PACKAGE_PIN D17 [get_ports ligtht]

set_property PACKAGE_PIN F18 [get_ports locked]
set_property IOSTANDARD LVCMOS33 [get_ports locked]

create_clock -period 20.000 -name sys_clk -waveform {0.000 10.000} -add [get_ports *sys_clk*]
set_input_jitter [get_clocks *sys_clk*] 0.200

set_false_path -from [get_ports valid]
set_false_path -from [get_ports rst_n]
