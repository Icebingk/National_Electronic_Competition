onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+ddr_clk -L xpm -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.ddr_clk xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {ddr_clk.udo}

run -all

endsim

quit -force
