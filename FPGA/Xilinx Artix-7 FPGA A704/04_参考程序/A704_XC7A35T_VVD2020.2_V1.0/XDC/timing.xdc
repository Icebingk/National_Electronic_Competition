
##########################################################################################
## Period
##########################################################################################
#create_clock -period 20.000 -name T_sys_clk -waveform {0.000 10.000} [get_ports sys_clk]



set_max_delay -datapath_only -from [get_pins UU7/io_sig_reg/C] -to * 20.0
set_max_delay -datapath_only -from [get_pins UU2/rst_n_temp_reg/C] -to * 10.0


set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins UU1/U0_sys_clk/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins UU1/U0_sys_clk/inst/mmcm_adv_inst/CLKOUT1]] 10.0
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins UU1/U0_sys_clk/inst/mmcm_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins UU1/U0_sys_clk/inst/mmcm_adv_inst/CLKOUT0]] 10.0
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins UU1/U0_sys_clk/inst/mmcm_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins UU3/u_ddr3/u_ddr3_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]] 10.0
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins UU3/u_ddr3/u_ddr3_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]] -to [get_clocks -of_objects [get_pins UU1/U0_sys_clk/inst/mmcm_adv_inst/CLKOUT1]] 10.0
