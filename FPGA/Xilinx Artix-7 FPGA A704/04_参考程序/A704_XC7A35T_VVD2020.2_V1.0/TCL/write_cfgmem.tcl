
set tcl_Dir [file dirname [info script]]

set pj_name    top
set top_name   top
set mcs_width  SPIx4
set flash_size 128 

write_cfgmem -format mcs -interface $mcs_width -size $flash_size -loadbit "up 0x0 $tcl_Dir/../Project/${pj_name}.runs/impl_1/${top_name}.bit" -force -file $tcl_Dir/../Result/${top_name}.mcs
write_cfgmem -format bin -interface $mcs_width -size $flash_size -loadbit "up 0x0 $tcl_Dir/../Project/${pj_name}.runs/impl_1/${top_name}.bit" -force -file $tcl_Dir/../Result/${top_name}.bin

file copy -force $tcl_Dir/../Project/${pj_name}.runs/impl_1/${top_name}.bit $tcl_Dir/../Result/ 

