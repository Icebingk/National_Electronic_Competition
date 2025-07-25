
#################################################################################################
## PIN
#################################################################################################
set_property PACKAGE_PIN R4 [get_ports sys_clk]
set_property PACKAGE_PIN T1 [get_ports {led[1]}]
set_property PACKAGE_PIN U1 [get_ports {led[0]}]
set_property PACKAGE_PIN P20 [get_ports rxd]
set_property PACKAGE_PIN T20 [get_ports txd]
set_property PACKAGE_PIN T3 [get_ports key]
#################################################################################################
## IOSTANDARD
#################################################################################################
set_property IOSTANDARD LVCMOS33 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports rxd]
set_property IOSTANDARD LVCMOS33 [get_ports txd]
set_property IOSTANDARD LVCMOS33 [get_ports key]
#################################################################################################
## SLEW
#################################################################################################


#################################################################################################
#
#################################################################################################
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 22 [current_design]



