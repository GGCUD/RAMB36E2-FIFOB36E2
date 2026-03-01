transcript on


do do/compile.do

vsim -t 1ps -coverage -voptargs=+acc -L unisim work.tb_fifo
do do/wave_fifo.do
run 10 us

puts "=== SIM DONE (GUI) ==="