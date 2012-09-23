

vlib work

if { [string match "verilog" $LANG] == 1 } {
    # TB and library inputs
    vlog   $VLIB $TB
} else {
    vlog  $VLIB ../../pnr/op_data/${toplevel}_final.v
    vcom $TB
}

# TB module name
vsim $TB_TOP

# VCD will be saved in "../vcd/$TB.vcd"
vcd file ../vcd/$toplevel.vcd
vcd add -r *
run 500 ns
vcd checkpoint
quit -f



