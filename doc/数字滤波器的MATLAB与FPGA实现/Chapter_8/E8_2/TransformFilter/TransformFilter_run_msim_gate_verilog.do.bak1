transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vlog -vlog01compat -work work +incdir+. {TransformFilter_8_1200mv_85c_slow.vo}

vlog -vlog01compat -work work +incdir+D:/altera/FPGAprj/duyong_matlab_fpga_altera_verilog/Chapter_8/E8_2/TransformFilter/simulation/modelsim {D:/altera/FPGAprj/duyong_matlab_fpga_altera_verilog/Chapter_8/E8_2/TransformFilter/simulation/modelsim/TransformFilter.vt}

vsim -t 1ps +transport_int_delays +transport_path_delays -L altera_ver -L cycloneive_ver -L gate_work -L work -voptargs="+acc" TransformFilter_vlg_tst

add wave *
view structure
view signals
run -all
