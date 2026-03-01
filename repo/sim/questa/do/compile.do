transcript on
onerror { quit -code 1 }
puts "=== COMPILE.DO START ==="
set root_dir [pwd]

if {[file exists work]} { vdel -all }
vlib work
vmap work work

if {[info exists env(UNISIM_LIB)]} { catch { vmap unisim $env(UNISIM_LIB) } }
if {[info exists env(XPM_LIB)]}    { catch { vmap xpm    $env(XPM_LIB) } }

set VCOM "vcom -2002 -explicit -work work -cover sbceft"

eval $VCOM [file join $root_dir rtl dbram.vhd]
eval $VCOM [file join $root_dir rtl fifo.vhd]
eval $VCOM [file join $root_dir ref dbram_ref.vhd]
eval $VCOM [file join $root_dir tb  tb_dbram_diff.vhd]
#eval $VCOM [file join $root_dir tb  tb_fifo.vhd]
puts "=== COMPILE.DO END ==="