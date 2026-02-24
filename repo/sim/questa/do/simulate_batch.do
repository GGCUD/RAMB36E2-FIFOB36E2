transcript on
onerror { quit -code 1 }
onbreak { quit -code 1 }

do do/compile.do

vsim -c -t 1ps -voptargs=+acc -L unisim work.tb_dbram_diff
run 20 us
quit -code 0