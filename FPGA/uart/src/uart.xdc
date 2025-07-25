set_property PACKAGE_PIN R4 [get_ports sys_clk]
set_property PACKAGE_PIN T3 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property PACKAGE_PIN N13  [get_ports rx]
set_property PACKAGE_PIN U17  [get_ports tx] 
set_property IOSTANDARD LVCMOS33 [get_ports rx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]

create_clock -period 20.000 -name sys_clk -waveform {0.000 10.000} -add [get_ports *sys_clk*]
set_input_jitter [get_clocks *sys_clk*] 0.200
set_false_path -from [get_ports rst_n]