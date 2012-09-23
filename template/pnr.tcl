global toplevel 
set toplevel a




# Script for SoC 8.* and 6.* versions ONLY.
#---------------------------------------------------------------------- 
#set the non-default options.(when library is different from OSU-180nm)
source ../conf/rtl2gds.config

global METALFIVENAME
global METALSIXNAME
global FILLERCELLNAME
global GDSMAPFILE
# POWERNET and GROUNDNET set to proper names at encounter.conf stage
global POWERNET
global GROUNDNET
#---------------------------------------------------------------------- 
set version [getVersion]
set flag 0

# Encounter 8.1 script
if { [string match "*8.*" $version] == 1 } {
    
    set flag 1
    ###################################
    # Run the design through Encounter
    ###################################
    
    #--------------------------------------------------------------
    #1. Setup the design
    #--------------------------------------------------------------
    loadConfig ../conf/encounter.conf 0
    commitConfig
   if {1 == [string equal ${METALFIVENAME} "NONE"]} {
      set METALFIVENAME "metal5"
   }
   if {1 == [string equal ${METALSIXNAME} "NONE"]} {
      set METALSIXNAME "metal6"
   }
   if {1 == [string equal ${FILLERCELLNAME} "NONE"]} {
      set FILLERCELLNAME "FILL"
   }
   if {1 == [string equal ${GDSMAPFILE} "NONE"]} {
      set GDSMAPFILE "../scripts/gds2_encounter.map"
   }
    
   # POWERNET and GROUNDNET set to proper names at encounter.conf stage
    #--------------------------------------------------------------
    #2. Create Initial Floorplan
    #--------------------------------------------------------------
    #---floorPlan -r <aspectRatio> [<rowDensity>   [<coreToLeft>
    #---                 <coreToBottom> <coreToRight> <coreToTop>]]
    #---
    floorplan -r 1.0 0.6 40 40 40 40
    # Or load the pre-created floorplan
    #loadFPlan ../op_data/{toplevel}.fp
    
    #--------------------------------------------------------------
    #3. Create Power Structures
    #--------------------------------------------------------------
    addRing -spacing_top 10 -spacing_bottom 10 \
	-width_left 10 -width_right 10 -width_bottom 10 -width_top 10 \
	-layer_bottom ${METALFIVENAME} -around core -center 1 \
	-layer_top ${METALFIVENAME} -spacing_right 10 -spacing_left 10 \
	-layer_right ${METALSIXNAME} -layer_left ${METALSIXNAME} \
	-nets "${GROUNDNET} ${POWERNET}"
    
    addStripe  -set_to_set_distance 100 -spacing 5 -xleft_offset 50 \
	-layer ${METALSIXNAME} -width 5 \
	-nets  "${GROUNDNET} ${POWERNET}"

    sroute -noBlockPins -noPadRings
    
    #--------------------------------------------------------------
    # 4. Placement
    #--------------------------------------------------------------
    setPlaceMode -placeIoPins true
    placeDesign
    saveDesign ../op_data/placeStage_intermediate_${toplevel}.dat    
    #--------------------------------------------------------------
    # 5. TrialRoute and initial timing results
    #--------------------------------------------------------------
    trialRoute
    timeDesign -preCTS -outDir ../reports/1.place_${toplevel}
    
    #--------------------------------------------------------------
    # 6. Run placement optimization
    #--------------------------------------------------------------
    setOptMode -verbose true -setupTargetSlack 0.0
    optDesign -preCTS 
    timeDesign -preCTS -outDir ../reports/2.preCTS_${toplevel}
    
    #--------------------------------------------------------------
    # 7. Run Clock Tree Sythesis
    #--------------------------------------------------------------
    setCTSMode -fixLeafInst true -moveGate true
    # Not providing -bufFootprint and -invFootprint.
    # Pick all the eligible buffers and inverters.
    createClockTreeSpec -file ../op_data/${toplevel}.ctstch
    specifyClockTree -clkfile ../op_data/${toplevel}.ctstch
    ckSynthesis -forceReconvergent -rguide cts.rguide \
	-report ../reports/${toplevel}.ctsrpt -fix_added_buffers
    
    # CTS reports and post-CTS timing analysis.
    trialRoute -highEffort -guide cts.rguide
    timeDesign -postCTS -outDir ../reports/3.postCTS_${toplevel}
    reportClockTree -localSkew -report ../reports/clock_localSkew.rpt
    reportClockTree -report ../reports/clockTree.rpt
    
    #--------------------------------------------------------------
    # 8. postCTS optimization.
    #--------------------------------------------------------------
    setOptMode -verbose true -setupTargetSlack 0.0
    optDesign -postCTS 
    setExtractRCMode -detail -assumeMetFill -noReduce
    timeDesign -postCTS -outDir ../reports/4.postCTSOpt_${toplevel}
    
    #--------------------------------------------------------------
    # 8. Routing and filler addition
    #--------------------------------------------------------------
    globalDetailRoute
    
    #--------------------------------------------------------------
    # 9. postRoute optimization.
    #--------------------------------------------------------------
    optDesign -postRoute
    ecoRoute
    
    # Add filler cells
    addFiller -cell ${FILLERCELLNAME} -prefix FILL
    # Connect all new cells to VDD/GND
    globalNetConnect ${POWERNET} -type tiehi
    #globalNetConnect ${POWERNET} -type pgpin -pin vdd -override
    #globalNetConnect ${POWERNET} -type pgpin -override
    globalNetConnect ${GROUNDNET} -type tielo
    #globalNetConnect ${GROUNDNET} -type pgpin -pin gnd -override
    #globalNetConnect ${GROUNDNET} -type pgpin -override
    
    timeDesign -postRoute -outDir ../reports/5.postRouteOpt_${toplevel}
    
    #--------------------------------------------------------------
    # 10. Save the database
    #--------------------------------------------------------------
    saveNetlist ../op_data/${toplevel}_final.v
    defout -floorplan -netlist -routing ../op_data/${toplevel}_final.def.gz
    saveDesign ../op_data/${toplevel}.dat
    
    # Output GDSII
    streamOut ../op_data/${toplevel}_final.gds2 \
	-mapFile ${GDSMAPFILE} -stripes 1 -units 1000 -mode ALL
    saveNetlist -excludeLeafCell final_excludeLeaf.v
    
    # Output DSPF RC Data
    rcOut -spf ../op_data/${toplevel}_final.dspf
    
    #--------------------------------------------------------------
    # 11. Check DRC and Connectivity
    #--------------------------------------------------------------
    verifyGeometry -report ../reports/${toplevel}_verifyGeometry.rpt
    verifyConnectivity -type all \
	-report ../reports/${toplevel}_verifyConnectivity.rpt
    
    summaryReport -nohtml -outfile ../reports/${toplevel}_summary.rpt
    reportGateCount -outfile ../reports/${toplevel}_gateCount.rpt
    
    puts "****************************************************"
    puts "* Encounter script finished                        *"
    puts "*                                                  *"
    puts "* Results:                                         *"
    puts "* --------                                         *"
    puts "* Layout:  pnr/op_data/${toplevel}_final.gds2                   *"
    puts "* Netlist: pnr/op_data/${toplevel}_final.v                      *"
    puts "* Timing:  pnr/reports/5.postRouteOpt_${toplevel}   *"
    puts "*                                                  *"
    puts "* Type 'win' to get the Main Window                *"
    puts "* or type 'exit' to quit                           *"
    puts "*                                                  *"
    puts "****************************************************"
    
}

# Encounter 6.2 script
if { [string match "*6.*" $version] == 1 } {

    set flag 1

    ###################################
    # Run the design through Encounter
    ###################################
    
    # Setup design and create floorplan
    loadConfig ../conf/encounter.conf
    commitConfig
   if {1 == [string equal ${METALFIVENAME} "NONE"]} {
      set METALFIVENAME "metal5"
   }
   if {1 == [string equal ${METALSIXNAME} "NONE"]} {
      set METALSIXNAME "metal6"
   }
   if {1 == [string equal ${FILLERCELLNAME} "NONE"]} {
      set FILLERCELLNAME "FILL"
   }
   if {1 == [string equal ${GDSMAPFILE} "NONE"]} {
      set GDSMAPFILE "../scripts/gds2_encounter.map"
   }
    
   # POWERNET and GROUNDNET set to proper names at encounter.conf stage
    #--------------------------------------------------------------
    
    # Create Initial Floorplan
    floorplan -r 1.0 0.6 40 40 40 40
    
    # Create Power structures
    addRing -width_left 10 -width_right 10 -width_bottom 10 -width_top 10 \
	-spacing_top 10 -spacing_bottom 10 -spacing_right 10 -spacing_left 10 \
	-around core -center 1 \
	-layer_bottom ${METALFIVENAME} \
	-layer_top ${METALFIVENAME} \
	-layer_right ${METALSIXNAME} \
	-layer_left ${METALSIXNAME} \
	-nets "${GROUNDNET} ${POWERNET}"
    
    addStripe  -set_to_set_distance 100 -spacing 5 -xleft_offset 50 \
	-layer ${METALSIXNAME} -width 5 \
	-nets "${GROUNDNET} ${POWERNET}"
    
    
    # Place standard cells
    amoebaPlace
    
    # Route power nets
    sroute -noBlockPins -noPadRings
    
    # Perform trial route and get initial timing results
    trialroute
    buildTimingGraph
    setCteReport
    reportTA -nworst  10 -net > ../reports/1.place_${toplevel}.rpt
    
    # Run in-place optimization
    # to fix setup problems
    setIPOMode -mediumEffort -fixDRC -addPortAsNeeded
    initECO ./ipo1.txt
    fixSetupViolation
    endECO
    buildTimingGraph
    setCteReport
    reportTA -nworst  10 -net > ../reports/2.preCTS_${toplevel}.rpt
    
    # Run Clock Tree Synthesis
    # -bufFootprint buf -invFootprint inv not provided.
    # Pick all the eligible buffers and inverters.
    createClockTreeSpec -output ../op_data/${toplevel}.ctstch 
    specifyClockTree -clkfile ../op_data/${toplevel}.ctstch
    ckSynthesis -rguide cts.rguide  -fix_added_buffers\
	-report ../reports/${toplevel}.ctsrpt -macromodel report.ctsmdl 
    
    # Output Results of CTS
    trialRoute -highEffort -guide cts.rguide
    extractRC
    reportClockTree -postRoute -localSkew -report ../reports/clock_localSkew.rpt
    reportClockTree -postRoute -report ../reports/clockTree.rpt
    
    # Run Post-CTS Timing analysis
    setAnalysisMode -setup -async -skew -autoDetectClockTree
    buildTimingGraph
    setCteReport
    reportTA -nworst  10 -net > ../reports/4.postCTSOpt_${toplevel}.rpt
    
    # Perform post-CTS IPO
    setIPOMode -highEffort -fixDrc -addPortAsNeeded -incrTrialRoute  -restruct -topomap
    initECO ipo2.txt
    setExtractRCMode -default -assumeMetFill
    extractRC
    fixSetupViolation -guide cts.rguide
    
    # Fix all remaining violations
    setExtractRCMode -detail -assumeMetFill
    extractRC
    if {[isDRVClean -maxTran -maxCap -maxFanout] != 1} {
	fixDRCViolation -maxTran -maxCap -maxFanout
    }
    
    endECO
    cleanupECO
    
    # Run Post IPO-2 timing analysis
    buildTimingGraph
    setCteReport
    #reportTA -nworst  10 -net > timing.rep.4.ipo2
    
    # Add filler cells
    addFiller -cell ${FILLERCELLNAME} -prefix FILL -fillBoundary
    
    # Connect all new cells to VDD/GND
    globalNetConnect ${POWERNET} -type tiehi
    #globalNetConnect ${POWERNET} -type pgpin -pin vdd -override
    #globalNetConnect ${POWERNET} -type pgpin -override
    
    globalNetConnect ${GROUNDNET} -type tielo
    #globalNetConnect ${GROUNDNET} -type pgpin -pin gnd -override
    #globalNetConnect ${GROUNDNET} -type pgpin -override
    
    # Run global Routing
    globalDetailRoute
    
    # Get final timing results
    setExtractRCMode -detail -noReduce
    extractRC
    buildTimingGraph
    setCteReport
    reportTA -nworst  10 -net > ../reports/5.postRouteOpt_${toplevel}.rpt
    
    # Output GDSII
    streamOut ../op_data/${toplevel}_final.gds2 \
	-mapFile ${GDSMAPFILE} -stripes 1 -units 1000 -mode ALL
    saveNetlist -excludeLeafCell ../op_data/${toplevel}_final.v
    
    # Output DSPF RC Data
    rcout -spf ../op_data/${toplevel}_final.dspf
    
    # Run DRC and Connection checks
    verifyGeometry -report ../reports/${toplevel}_verifyGeometry.rpt
    verifyConnectivity -type all -report \
	../reports/${toplevel}_verifyConnectivity.rpt
    
    savedesign ../op_data/${toplevel}.dat
    summaryreport -nohtml -outfile ../reports/${toplevel}_summary.rpt
    reportgatecount -outfile  ../reports/${toplevel}_gateCount.rpt

    puts "****************************************************"
    puts "* Encounter script finished                        *"
    puts "*                                                  *"
    puts "* Results:                                         *"
    puts "* --------                                         *"
    puts "* Layout:  pnr/op_data/${toplevel}_final.gds2                   *"
    puts "* Netlist: pnr/op_data/${toplevel}_final.v                      *"
    puts "* Timing:  pnr/reports/5.postRouteOpt_${toplevel}   *"
    puts "*                                                  *"
    puts "* Type 'win' to get the Main Window                *"
    puts "* or type 'exit' to quit                           *"
    puts "*                                                  *"
    puts "****************************************************"
    
}

#---if { $flag == 0 } {
#--- 
#---    puts "Please run SoC Encounter in version 6.2 or 8.1"
#---    puts "Else manaully modify the version settings in the TOP-DIR/template/pnr.tcl script"
#---    puts "Current version of SoC Encounter is $version"
#---    exit
#---    
#---}

