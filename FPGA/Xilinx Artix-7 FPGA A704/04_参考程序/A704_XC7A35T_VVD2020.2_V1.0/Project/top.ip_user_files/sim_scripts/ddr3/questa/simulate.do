onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib ddr3_opt

do {wave.do}

view wave
view structure
view signals

do {ddr3.udo}

run -all

quit -force
