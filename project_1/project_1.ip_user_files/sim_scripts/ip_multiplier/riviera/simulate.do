transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+ip_multiplier  -L xpm -L xbip_utils_v3_0_13 -L xbip_pipe_v3_0_9 -L xbip_bram18k_v3_0_9 -L mult_gen_v12_0_21 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.ip_multiplier xil_defaultlib.glbl

do {ip_multiplier.udo}

run 1000ns

endsim

quit -force
