

sh date
#--------------------------------------------------------------
#  General settings.
#--------------------------------------------------------------
# Make enable_scan 1 for scan insertion.
set enable_scan 0 
# Make enable_clock_gating 1 for low power clock gating.
set enable_clock_gating 0
#/* The name of the clock pin  */
set clock_pin clk

#/* formality ( To check logical equivalence b/w rtl and netlist using Synopsys Formality tool)
#----set_svf ../op_data/${toplevel}.svf

set high_fanout [list $clock_pin ]

if {$enable_scan} {
    #/* Define format of test signals */
    set test_scan_enable_port_naming_style SCANEN%s
    set test_scan_in_port_naming_style SCANIN%s
    set test_scan_out_port_naming_style SCANOUT%s
    set test_clock_port_naming_style SCANCLK
}
#--------------------------------------------------------------
# Set the technology parameters
#--------------------------------------------------------------
#/* link library, target library etc  */
source -echo -verbose ../scripts/technology.tcl

#--------------------------------------------------------------
# Read RTL and analyze
#--------------------------------------------------------------
# list of source files to be compiled
source -echo -verbose ../scripts/rtl.tcl

#---if { [string match "verilog" $RTLLANG] == 1 } {
#---    foreach module_name $hdl_files {
#---	analyze -format verilog [list $module_name]
#---    }
#---} else {
#---    foreach module_name $hdl_files {
#---	analyze -format vhdl [list $module_name]
#---    }
#---}
#---
#---
#---foreach module_name $hdl_files {
#---    analyze -library $library_name -format vhdl [list $module_name]
#---}

#--------------------------------------------------------------
# Insert Clock Gating
#--------------------------------------------------------------
echo "Wait for PowerOpt license"
while {![get_license {Power-Optimization}]}  {
    echo -n .
    sh ( sleep 5 )
}
if {$enable_clock_gating} {
  set_clock_gating_style  \
    -sequential_cell latch  \
    -positive_edge_logic {integrated:IGC_16X} \
    -control_point before \
    -control_signal scan_enable \
    -minimum_bitwidth 1 \
    -max_fanout 2
}
elaborate  $toplevel 
if {$enable_clock_gating} {
insert_clock_gating > ../logs/insert_clock_gating.log
}
#--------------------------------------------------------------
# Link and Uniquify
#--------------------------------------------------------------
current_design $toplevel
link
uniquify

#--------------------------------------------------------------
# Constraints ( clock, I/O delay etc )
#--------------------------------------------------------------
source -echo -verbose ../scripts/constraints.tcl

#--------------------------------------------------------------
# Synthesis
#--------------------------------------------------------------
set_max_transition 1 ${toplevel}

#/* Buffer all port nets */
foreach_in_collection design [get_designs "*"] {
    current_design $design
    set_fix_multiple_port_nets -all -buffer_constants
}
current_design ${toplevel}
set_fix_multiple_port_nets -all -buffer_constants

#/* Propagate constraints if using clock gating */
#propagate_constraints -gate_clock
propagate_constraints
compile -map_effort medium
check_design > ../reports/${toplevel}_check_design_initial.rpt 
compile -incremental_mapping -map_effort medium

if {$enable_scan} {
    #/* Compile for scan */
    compile -scan -incremental
}

#/*  Change names */                                              
change_names -rules verilog -hierarchy
check_design > ../reports/${toplevel}_check_design_postsynth.rpt 

#--------------------------------------------------------------
#  Scan Insertion
#--------------------------------------------------------------
if {$enable_scan} {
    set_scan_configuration -style multiplexed_flip_flop
    set_scan_configuration -chain_count 2
    set_scan_configuration -add_lockup true
    
    create_test_protocol
    dft_drc > ../reports/preDFT_drc.rprt
    preview_dft
    insert_dft
    dft_drc > ../reports/postDFT_drc.rprt

    compile -scan -incremental
}

check_design > ../reports/${toplevel}_check_design_final.rpt 

#--------------------------------------------------------------
# Save the database
#--------------------------------------------------------------
write -f verilog -hier -output ../op_data/${toplevel}.v
write -f vhdl -hier -output ../op_data/${toplevel}.vhd
write -f ddc -hier -output ../op_data/${toplevel}.ddc
write_sdc -version 1.2 ../op_data/${toplevel}.sdc
if {$enable_scan} {
    write_scan_def -o ../op_data/scan.def
}

#--------------------------------------------------------------
# Generate the reports
#--------------------------------------------------------------
#/* report clock gating */
if {$enable_clock_gating} {
    identify_clock_gating
    report_clock_gating > ../reports/clk_gate.rpt
    #report_clock_gating -verbose > ../reports/clk_gate_verbose.rpt
}

#/* report scan chains */
if {$enable_scan} {
    report_scan_chain > ../reports/scan_chain.rpt
    report_scan_path  -cell all  > ../reports/scan_path_cell.rpt
    report_scan_path  -chain all > ../reports/scan_path_chain.rpt
}

#/* timing report */
report_timing -nets -cap -transition -nworst 1  -max_paths 10 > ../reports/timing_full.rpt
set_false_path -from [all_inputs]
set_false_path -to [all_outputs]
report_timing -nets -cap -transition -nworst 1  -max_paths 10 > ../reports/timing_reg2reg.rpt

report_area > ../reports/area.rpt
report_qor > ../reports/qor.rpt
report_constraint -all_violators > ../reports/constraint.rpt
#report_net_fanout -threshold 50 > ../reports/net_fanout.rpt
report_cell > ../reports/cell.rpt
report_power > ../reports/power.rpt

#--------------------------------------------------------------
# Exit
#--------------------------------------------------------------
sh date
quit
#--------------------------------------------------------------
