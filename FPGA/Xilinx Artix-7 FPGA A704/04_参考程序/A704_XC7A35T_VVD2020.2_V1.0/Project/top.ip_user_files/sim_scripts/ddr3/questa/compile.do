vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib

vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xil_defaultlib  \
"../../../../../RTL/ddr_ctrl/ddr3/ddr3_sim_netlist.v" \


vlog -work xil_defaultlib \
"glbl.v"

