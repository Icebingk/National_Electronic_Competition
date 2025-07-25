onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib ddr_clk_opt

do {wave.do}

view wave
view structure
view signals

do {ddr_clk.udo}

run -all

quit -force
