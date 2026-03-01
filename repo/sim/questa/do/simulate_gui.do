transcript on


do do/compile.do

vsim -t 1ps -coverage -voptargs=+acc -L unisim work.tb_dbram_diff
do do/wave.do
run 10 us

puts "=== SIM DONE (GUI) ==="