


global tb_top
source ../scripts/tb.list
set version [getVersion]
set flag 0

# Encounter 8.1 script
if { [string match "*8.*" $version] == 1 } {
    
    set flag 1
    
    ############################################
    # Report the power in Encounter (VCD based)
    ############################################
    
    #--------------------------------------------------------------
    #1. Setup the design
    #--------------------------------------------------------------
    #restoreDesign ../op_data/${toplevel}.dat.dat
    source ../op_data/${toplevel}.dat
    
    # Needed only if parasitics are not present in the database, may comment out the following lines.
    setExtractRCMode -detail -assumeMetFill -noReduce
    extractRC
    
    #--------------------------------------------------------------
    #2. Read the activity file (VCD)
    #--------------------------------------------------------------
    read_activity_file ../../simulation/vcd/${toplevel}.vcd -format VCD -vcd_block ${toplevel} -vcd_scope ${tb_top} -start  0 -end 500
    propagate_activity
    
    #--------------------------------------------------------------
    #3. Report power.
    #--------------------------------------------------------------
    report_power -outfile ../reports/${toplevel}_power.vcdrpt
    report_power -instances {*} -outfile ../reports/${toplevel}_instpower.vcdrpt
    
    puts "****************************************************"
    puts "* Encounter VCD based power calculation finished   *"
    puts "*                                                  *"
    puts "* VCD: ../../simulation/vcd/${toplevel}.vcd        *"
    puts "* Database: ../op_data/${toplevel}.dat             *"
    puts "* Results:                                         *"
    puts "* --------                                         *"
    puts "* Power:  ../reports/${toplevel}_power.vcdrpt      *"
    puts "*      :  ../reports/${toplevel}_instpower.vcdrpt  *"
    puts "*                                                  *"
    puts "* Type 'win' to get the Main Window                *"
    puts "* or type 'exit' to quit                           *"
    puts "*                                                  *"
    puts "****************************************************"
    
}


# Encounter 6.2 script
if { [string match "*6.*" $version] == 1 } {

    set flag 1
    #--------------------------------------------------------------
    #1. Setup the design
    #--------------------------------------------------------------
    source ../op_data/${toplevel}.dat
    setExtractRCMode -detail -assumeMetFill
    extractRC
    autoFetchDCSources vdd
    savePadLocation -file paAutoGen.vdd.pp
    probePower
    updatePower -noRailAnalysis -vcd ../../simulation/vcd/${toplevel}.vcd -vcdTop ${tb_top} -noTop -start 0.0 -report ../reports/${toplevel}_power.vcdrpt -reportInstancePower ../reports/${toplevel}_instpower.vcdrpt -timeUnit ps vdd
    
    
    puts "****************************************************"
    puts "* Encounter VCD based power calculation finished   *"
    puts "*                                                  *"
    puts "* VCD: simulation/vcd/${toplevel}.vcd          *"
    puts "* Database: pnr/op_data/${toplevel}.dat               *"
    puts "* Results:                                         *"
    puts "* --------                                         *"
    puts "* Power:  pnr/reports/${toplevel}_power.vcdrpt        *"
    puts "*      :  pnr/reports/${toplevel}_instpower.vcdrpt    *"
    puts "*                                                  *"
#    puts "* Type 'win' to get the Main Window                *"
#    puts "* or type 'exit' to quit                           *"
#    puts "*                                                  *"
#    puts "****************************************************"
    
    
}

#---if { [string match "0" $flag] == 0 } {
#--- 
#---    puts "Please run SoC Encounter in version 6.2 or 8.1"
#---    puts "Else manaully modify the version settings in the TOP-DIR/template/pnr.tcl script"
#---    puts "Current version of SoC Encounter is $version"
#---    exit
#---    
#---}

    
exit    
    
    
    
