quietly WaveActivateNextPane {} 0
delete wave *

add wave -noupdate /tb_fifo/aclk
add wave -noupdate /tb_fifo/aresetn

add wave -noupdate -divider "WRITE"
add wave -noupdate /tb_fifo/din
add wave -noupdate /tb_fifo/wr_en
add wave -noupdate /tb_fifo/full

add wave -noupdate -divider "READ"
add wave -noupdate /tb_fifo/rd_en
add wave -noupdate /tb_fifo/empty
add wave -noupdate /tb_fifo/dout_valid
add wave -noupdate /tb_fifo/dout

add wave -noupdate -divider "DUT internal"
add wave -noupdate /tb_fifo/u_dut/wr_ptr
add wave -noupdate /tb_fifo/u_dut/rd_ptr
add wave -noupdate /tb_fifo/u_dut/count
add wave -noupdate /tb_fifo/u_dut/wr_hs
add wave -noupdate /tb_fifo/u_dut/rd_hs

update