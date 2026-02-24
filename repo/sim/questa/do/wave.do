quietly WaveActivateNextPane {} 0
quietly delete wave *

add wave -divider "TB"
add wave -radix hex sim:/tb_dbram_diff/aclk
add wave -radix hex sim:/tb_dbram_diff/aresetn

add wave -divider "Inputs"
add wave -radix hex sim:/tb_dbram_diff/addr_a_i
add wave -radix hex sim:/tb_dbram_diff/addr_b_i
add wave -radix hex sim:/tb_dbram_diff/write_a_i
add wave -radix hex sim:/tb_dbram_diff/write_b_i
add wave -radix hex sim:/tb_dbram_diff/write_a_data_i
add wave -radix hex sim:/tb_dbram_diff/write_b_data_i

add wave -divider "Outputs: DUT vs REF"
add wave -radix hex sim:/tb_dbram_diff/dut_ra
add wave -radix hex sim:/tb_dbram_diff/ref_ra
add wave -radix hex sim:/tb_dbram_diff/dut_rb
add wave -radix hex sim:/tb_dbram_diff/ref_rb

configure wave -namecolwidth 250
configure wave -valuecolwidth 160
configure wave -timelineunits ns
update