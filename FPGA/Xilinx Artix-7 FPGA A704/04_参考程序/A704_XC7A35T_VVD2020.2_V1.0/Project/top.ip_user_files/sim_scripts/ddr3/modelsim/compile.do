vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xil_defaultlib  -incr \
"../../../../../RTL/ddr_ctrl/ddr3/ddr3_sim_netlist.v" \


vlog -work xil_defaultlib \
"glbl.v"

