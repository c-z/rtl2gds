#!/usr/bin/perl
#
# Author: Arun. C (arunc@ee.iitb.ac.in)
# Copyright: VLSI-Design Lab, IIT-Bombay.
# Project Guide: Prof. Madhav. P. Desai

# Ver5
#        Truncation of floating point while evaluating constraints.
#        Synthesis - DesignWare path in technology.tcl corrected.
#                    clock-gating option removed from default.
#        rtl2gds.config introduced.
#            PNR and Power calculations- 
#            Power routing MetalLayer names corrected for other technologies.
#            Power and Ground net names corrected for other technologies.
#            FillerCell Name corrected for other technologies.
#            StreamOut map file corrected for other technologies.
#
# Ver4 - multi file/multi library support for VHDL
#        "-rtl" supports 3 options, 
#        single verilog file/single vhdl file or vhdl file list
#        Changed rtl.list to rtl.tcl
#
# Ver3 - tb_top corrected in powercalc, vhdl/verilog in simulation
# Ver2 - RTL2GDS home, LICENSE
# Ver1 - enhanced constraint list, man, max_area conversion
# Ver0 - enhanced option list, included tool checking

#use strict; use warnings; use diagnostics;

use Fcntl;
use File::Path;
use File::Copy;
use File::Find;
use Cwd;

########################################################################
# Main Program.
########################################################################
# Check for 0 arguments
if ($#ARGV<0) { &usage(1);}
#-----------------------------------------------------------------------
# Import/Check for RTL2GDSHOME
&check_rtl2gdshome();
$RTL2GDSHOME=$ENV{RTL2GDSHOME};
$RTL2GDS_INST=$ENV{RTL2GDS_INST};
#-----------------------------------------------------------------------
# Check miscellaneous options.
# 1. Check for "help" option
@INPUTARGS = @ARGV;
foreach $option (@INPUTARGS) {
    $option =~  tr/A-Z/a-z/;
    if ($option =~ "-hel") {
	&help();
    }
}

# 2. Check for "genScriptOnly" option
@INPUTARGS = @ARGV;
foreach $option (@INPUTARGS) {
#    $option =~  tr/A-Z/a-z/;
    if ($option =~ "genScr") {
	$option =~ s/-genScr.*=//;
	system("mkdir -p $option");
	chdir $option;

	system ("cp -rf $RTL2GDS_INST/synthesis .");
	system ("cp -rf $RTL2GDS_INST/simulation .");
	system ("cp -rf $RTL2GDS_INST/pnr .");
	system ("cp -rf $RTL2GDS_INST/rtl .");
	system ("cp -rf $RTL2GDS_INST/template .");
	system ("cp -f $RTL2GDS_INST/template/rtl2gds.config ./pnr/conf/");
	system ("cp -f  $RTL2GDS_INST/Back-End_DesignFlow.pdf .");

	system("mkdir -p ./man1");
	system ("cp -f $RTL2GDS_INST/rtl2gds.1 ./man1/");

	system ("cp -f $RTL2GDS_INST/rtl2gds.pdf .");

#	exit;
    }
}
#-----------------------------------------------------------------------
$top_dir = getcwd();

# Pass only local copies of @ARGV
@INPUTARGS = @ARGV;
# Prase different options.
&evaluate_rtl_options(@INPUTARGS);
# Check for tool binaries, installed or not.
&check_tool_binaries();
# Set the libraries based on input options.
@INPUTARGS = @ARGV;
&set_library(@INPUTARGS);
# Set the constraints based on input options.
@INPUTARGS = @ARGV;
&make_constraints(@INPUTARGS);
#-----------------------------------------------------------------------
# Set the directories.
$syn_dir = $top_dir."/synthesis/run";
$pnr_dir = $top_dir."/pnr/run";
$sim_dir = $top_dir."/simulation/run";
$pow_dir = $top_dir."/pnr/run";


# Exit out for "genScriptOnly" option
foreach $option (@ARGV) {
    $option =~  tr/A-Z/a-z/;
    if ($option =~ "genscr") {
	exit(1);
    }
}
#-----------------------------------------------------------------------
# Tool Execution.
#-----------------------------------------------------------------------
# Check for "all" option
foreach $option (@ARGV) {
  $option =~  tr/A-Z/a-z/;
  if ($option =~ "-all") {
      print "\nRUNNING SYNTHESIS IN \"$syn_dir\"\n";
      #---------------------------------
      # Run synthesis
      chdir $top_dir;
      chdir $syn_dir;
      system ("bash run_dc.bash");
      
      print "\nRUNNING PNR IN \"$pnr_dir\"\n";
      #---------------------------------
      # Run pnr
      chdir $top_dir;
      # Check for rtl2gds.config file
      if (-e "$pnr_dir/../conf/rtl2gds.config") {
	  chdir $pnr_dir;
	  system ("bash run_pnr.bash");
      }
      else {
	  print "$pnr_dir/conf/rtl2gds.config does not exist\n";
	  print "Either use -genScr option to clear and generate all the directories and files again OR copy from $top_dir/template/rtl2gds.config to $pnr_dir/conf/rtl2gds.config and invoke again\n";
	  exit;
      }
      
      print "\nRUNNING SIMULATION IN \"$sim_dir\"\n";
      #---------------------------------
      # Run simulation
      chdir $top_dir;
      chdir $sim_dir;
      system ("bash run_sim.bash");
      
      print "\nRUNNING POWER ANALYSIS (VCD BASED) IN \"$pnr_dir\"\n";
      #---------------------------------
      # Run VCD based power calculation.
      chdir $top_dir;
      chdir $pow_dir;
      system ("bash run_power.bash");
  }

}
# Individiual tool execution.
foreach $option (@ARGV) {
  $option =~  tr/A-Z/a-z/;
  if ($option =~ "-syn") {
    print "\nRUNNING SYNTHESIS IN \"$syn_dir\"\n";
    #---------------------------------
    # Run synthesis
    chdir $syn_dir;
    system ("bash run_dc.bash");
  }

  if ($option =~ "-pnr") {
    print "\nRUNNING PNR IN \"$pnr_dir\"\n";
    #---------------------------------
    # Run pnr
    # Check for rtl2gds.config file
    if (-e "$pnr_dir/../conf/rtl2gds.config") {
	chdir $pnr_dir;
	system ("bash run_pnr.bash");
    }
    else {
	print "$pnr_dir/conf/rtl2gds.config does not exist\n";
	print "Either use -genScr option to clear and generate all the directories and files again OR copy from $top_dir/template/rtl2gds.config to $pnr_dir/conf/rtl2gds.config\n";
	exit;
    }
    
  }

  if ($option =~ "-sim") {
    print "\nRUNNING SIMULATION IN \"$sim_dir\"\n";
    #---------------------------------
    # Run simulation
    chdir $sim_dir;
    system ("bash run_sim.bash");
  }

  if ($option =~ "-pow") {
    print "\nRUNNING POWER ANALYSIS (VCD BASED) IN \"$pnr_dir\"\n";
    #---------------------------------
    # Run VCD based power calculation.
    chdir $pow_dir;
    system ("bash run_power.bash");
  }
}

########################################################################
# END of main.
########################################################################

########################################################################
# -----  sub-routines  -------------------------------------------------
########################################################################
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
sub check_rtl2gdshome {
    $RTL2GDSHOME=$ENV{RTL2GDSHOME};
    $RTL2GDS_INST=$RTL2GDSHOME."/rtl2gds_install";
    if (!(-e $RTL2GDS_INST)) {
	print "\nERROR: \"RTL2GDSHOME\" env variable not set properly";
	print "\nSet the \"RTL2GDHOME\" env variable to proper rtl2gds utility installation path\n";
	print "WARNING: Default RTL2GDSHOME set to /usr/bin\n";
	$RTL2GDSHOME="/usr/bin";
	$RTL2GDS_INST=$RTL2GDSHOME."/rtl2gds_install";
	if (!(-e $RTL2GDS_INST)) {
	    print "ERROR: rtl2gds utility NOT found in \"$RTL2GDSHOME\" \n\n";
	    exit(2);
	}
    }
    $ENV{RTL2GDSHOME}=$RTL2GDSHOME;
    $ENV{RTL2GDS_INST}=$RTL2GDS_INST;
}
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
sub evaluate_rtl_options {
  $rtl_flag = 0;
  $top_flag = 0;
  $sim_flag1 = 0;
  $sim_flag2 = 0;

  #---------------------------------
  # set LIB and TECH default/based on options
  $libvar="$ENV{RTL2GDS_INST}/LIB";
  $techvar="tsmc018";
  $lib_flag=0;
  $tech_flag=0;
  foreach $option (@_) {
      #---------------------------------
      if ($option =~ "-lib=") {
	  $option =~ s/-lib=//;
	  $libvar=$option;
	  $lib_flag=1;
      }
      #---------------------------------
      if ($option =~ "-tech=") {
	  $option =~ s/-tech=//;
	  $techvar=$option;
	  $tech_flag=1;
      }
      #---------------------------------
      $ENV{'LIB'} = $libvar;
      $ENV{'TECH'} = $techvar;
  }
  if($lib_fag eq 0) {
      print "\n WARNING: Library path taken as \"$ENV{LIB}\" (DEFAULT) ";
      print "\n WARNING: Technology taken as \"$ENV{TECH}\" (DEFAULT/USER SETTING) ";
      print "\n INFO: Override using --lib_lef, --lib_tlf, --lib_db, --lib_conv, --lib_v options\n ";
  }

  $tb_options="\n";
  foreach $option (@_) {
#    $option =~  tr/A-Z/a-z/;
    #---------------------------------
    if ($option =~ "-rtl=") {
      $option =~ s/-rtl=//;
      $file_options = $options;
#      $option = "set RTL ".$option;
      #---------------------------------
      # Identify if its a list of VHDL files or single VHDL/Verilog file.
      if ($option =~ /\.vhd/) {
	  # Option1 - single vhdl file
	  $option = "analyze -format vhdl $option";
	  copy("./template/rtl.tcl","./synthesis/scripts/rtl.tcl");
	  &prepend_file("./synthesis/scripts/rtl.tcl",$option);
	  $rtl_flag = 1;

      } elsif ($option =~ /\.v/) {
	  # Option2 - single verilog file
	  $option = "analyze -format verilog $option";
	  copy("./template/rtl.tcl","./synthesis/scripts/rtl.tcl");
	  &prepend_file("./synthesis/scripts/rtl.tcl",$option);
	  $rtl_flag = 1;
	  
      } else {
	  # Option3 - vhdl file list with libraries
	  $file = $option;
	  copy("./template/rtl.tcl","./synthesis/scripts/rtl.tcl");
	  $rtl_flag = 1;

	  open (FILELIST,'<', "$file")||
	      die "ERROR: No VHDL list provided -> $file\nNo such file or directory at $file";
	  # reverse the file list so that order is maintained
	  #@VHDLLIST = reverse <FILELIST>;
	  @VHDLLIST = <FILELIST>; # No need to reverse

	  foreach $line (@VHDLLIST) {
	      $_= $line;
	      chomp;
	      my @list = split;
#	      print "@list, $list[1]\n";
	      if ($list[0] =~ /\w/) { # Check for word
		  if ($list[1] =~ /\w/) { # Check for default work library
		      $option = "analyze -library $list[1] -format vhdl $list[0]";
		      $design_lib ="define_design_lib $list[1] -path ./$list[1]"; 
		      &prepend_file("./synthesis/scripts/rtl.tcl",$option);
		      &prepend_file("./synthesis/scripts/rtl.tcl",$design_lib);
		  } else {
		      $option = "analyze -library work -format vhdl $list[0]";
		      $design_lib ="define_design_lib WORK -path ./work"; 
		      &prepend_file("./synthesis/scripts/rtl.tcl",$option);
		      &prepend_file("./synthesis/scripts/rtl.tcl",$design_lib);
		  }
	      }
	  }
	  $option ="";
	  close (FILELIST)
      }
      #---------------------------------

      $tb_options = $tb_options."$option\n";
      # Identify the RTL language used
      if ($file_option =~ /\.vhd/) {
	  $lang=vhdl;
	  &prepend_file("./synthesis/scripts/rtl.tcl","set RTLLANG vhdl");
      } elsif ($file_option =~ /\.v/) {
	  $lang = verilog;
	  &prepend_file("./synthesis/scripts/rtl.tcl","set RTLLANG verilog");
      } else {
	  $lang=vhdl;
	  &prepend_file("./synthesis/scripts/rtl.tcl","set RTLLANG vhdl");
      }
      $tb_options = $tb_options."set RTLLANG $lang\n";
    }
    #---------------------------------

    if ($option =~ "-tb=") {
      $option =~ s/-tb=//;
      $tb_options = $tb_options."set TB $option\n";
      $sim_flag1 = 1;
# Identify the tb language used
      if ($option =~ /\.vhd/) {
	$lang=vhdl;
      } else {
	$lang = verilog;
      }
      $tb_options = $tb_options."set LANG $lang\n";
    }
    #---------------------------------
    if ($option =~ "-tb_top=") {
      $option =~ s/-tb_top=//;
      $tb_options = $tb_options."set TB_TOP $option\n";
      $sim_flag2 = 1;

      # version-3 modification for tb_top
      # get tb_top variable available in power calculcation also.
      $option = "global tb_top \nset tb_top ".$option;
      copy ("./template/tb.list",  "./pnr/scripts/tb.list");
      &prepend_file("./pnr/scripts/tb.list",$option);

    }
    #---------------------------------
    if ($option =~ "-rtl_top=") {
      $option =~ s/-rtl_top=//;

      $option = "global toplevel \nset toplevel ".$option;
      copy("./template/compile_dc.tcl","./synthesis/scripts/compile_dc.tcl");
      &prepend_file("./synthesis/scripts/compile_dc.tcl",$option);

      copy("./template/pnr.tcl","./pnr/scripts/pnr.tcl");
      &prepend_file("./pnr/scripts/pnr.tcl",$option);

      copy("./template/power.tcl","./pnr/scripts/power.tcl");
      &prepend_file("./pnr/scripts/power.tcl",$option);

      $tb_options = $tb_options."$option\n";
      $top_flag = 1;
    }

  }

# Prepare the simulation files
  copy("./template/simulate.do","./simulation/run/simulate.do");
  &prepend_file("./simulation/run/simulate.do",$tb_options);

# Check for flags/warnings
  if($rtl_flag eq 0) {
    print "\nWARNING: \"-rtl=\" option not set\n";
    print "This will result in improper RTL being read during synthesis\n";
    print ("INFO: Ignore if task is NOT -syn or -all\n");
  }

  if($top_flag eq 0) {
    print "\nWARNING: \"-rtl_top=\" option not set\n";
    print "Set \"-rtl_top=\" for proper running\n";
  }

  if($sim_flag1 eq 0) {
    print "\nWARNING: \"-tb=\" option not set\n";
    print "This will result in improper TestBench being read during simulation\n";
    print ("INFO: Ignore if task is NOT -sim or -all\n");
  }

  if($sim_flag2 eq 0) {
    print "\nWARNING: \"-tb_top=\" option not set\n";
    print ("INFO: Ignore if task is NOT -sim or -all\n");
  }


}
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
sub make_constraints {
  $constraints = "";
  foreach $option (@_) {
    $option =~  tr/A-Z/a-z/;
    #---------------------------------
    # Convert the max_area option to dimensionless quantity (SDC convention)
    if ($option =~ "max_area=") {
	$option =~ s/-max_area=//;
	
	$LIB=$ENV{LIB};
	$TECH=$ENV{TECH};
	open (A, "${LIB}/conversion");
	while (<A>) {
	    chomp;
	    if ($_ =~ $TECH) {
		$val = $_;
		$val =~ s/$TECH=//;
	    }
	    
	}
	close (A); 
	$area=${option} / ${val};
	$constraints = $constraints."\nset_max_area $area\n";
    }
    #---------------------------------
    if ($option =~ "frequency") {
      $option =~ s/-frequency=//;
      $constraints = $constraints."\nset clk_freq_MHz $option\n";
    }
    #---------------------------------
    if ($option =~ "io_input_delay") {
      $option =~ s/-io_input_delay=//;
      $constraints = $constraints."set input_delay_ns $option\n";
    }
    #---------------------------------
    if ($option =~ "io_output_delay") {
      $option =~ s/-io_output_delay=//;
      $constraints = $constraints."set output_delay_ns $option\n";
    }
    #---------------------------------
    if ($option =~ "clk_latency") {
      $option =~ s/-clk_latency=//;
      $constraints = $constraints."set clk_latency $option\n";
    }
    #---------------------------------
    if ($option =~ "clk_uncertainty") {
      $option =~ s/-clk_uncertainty=//;
      $constraints = $constraints."set clk_uncertainty $option\n";
    }

  }
  copy("./template/constraints.tcl","./synthesis/scripts/constraints.tcl");
  &prepend_file("./synthesis/scripts/constraints.tcl",$constraints);
#  print "\nConstraints = $constraints\n";
}

#-----------------------------------------------------------------------
# Add the argument to the beginning of the file
#-----------------------------------------------------------------------
sub prepend_file {
  my ($file, $newline)=@_;
#  my $file=shift @_;

  {
    local @ARGV = ($file);
#    local $^I = '.org';
    local $^I = '';

    while(<>){
      if ($. == 1) {
	print "$newline$/";
	print;
      }
      else {
	print;
      }
    }
  }
}
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
sub set_library {

    $LIB=$ENV{LIB};
    $TECH=$ENV{TECH};
    $ENV{'LIBLEF'} = $LIB."/lib/".$TECH."/lib/osu018_stdcells.lef";
    $ENV{'LIBTLF'} = $LIB."/lib/".$TECH."/lib/osu018_stdcells.tlf";
    $ENV{'LIBDB'} = $LIB."/lib/".$TECH."/lib/osu018_stdcells.db";
    $ENV{'LIBV'} = $LIB."/lib/".$TECH."/lib/osu018_stdcells.v";
    $ENV{'LIBCONV'} = $LIB."/conversion";

    # set the individual libs based on options.
    foreach $option (@_) {
	if ($option =~ "--lib_lef=") {
	    $option =~ s/--lib_lef=//;
	    $ENV{'LIBLEF'} = $option;
	}
	#---------------------------------
	if ($option =~ "--lib_tlf=") {
	    $option =~ s/--lib_tlf=//;
	    $ENV{'LIBTLF'} = $option;
	}
	#---------------------------------
	if ($option =~ "--lib_conv=") {
	    $option =~ s/--lib_conv=//;
	    $ENV{'LIBCONV'} = $option;
	}
	#---------------------------------
	if ($option =~ "--lib_db=") {
	    $option =~ s/--lib_db=//;
	    $ENV{'LIBDB'} = $option;
	}
	if ($option =~ "--lib_v=") {
	    $option =~ s/--lib_v=//;
	    $ENV{'LIBV'} = $option;
	}

	#---------------------------------
    }

    copy("./template/technology.tcl","./synthesis/scripts/technology.tcl");
    &prepend_file("./synthesis/scripts/technology.tcl","set LIBPATH ${LIB}/lib/${TECH}/lib\n");
    &prepend_file("./synthesis/scripts/technology.tcl","set TLIB $ENV{LIBDB}\n");

    #copy("./template/rtl2gds.config","./pnr/conf/rtl2gds.config");
    copy("./template/encounter.conf","./pnr/conf/encounter.conf");
    &prepend_file("./pnr/conf/encounter.conf","set LEF $ENV{LIBLEF}\n");
    &prepend_file("./pnr/conf/encounter.conf","set TLF $ENV{LIBTLF}\n");

    &prepend_file("./simulation/run/simulate.do","set VLIB $ENV{LIBV}\n");

}
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
sub check_tool_binaries {
    $error_flag=0;
    # Check encounter
    my @paths = grep { -x "$_/encounter" } split /:/, $ENV{PATH}, $ENV{path};
    unless ( scalar @paths ) {
	print "\nERROR: SoC Encounter not available\n";
	print "Include SoC Encounter installation directory in environment variable \"PATH\"\n";
	$error_flag=1;
    }

    # Check DC
    my @paths = grep { -x "$_/dc_shell" } split /:/, $ENV{PATH}, $ENV{path};
    unless ( scalar @paths ) {
	print "\nERROR: Design-Compiler not available\n";
	print "Include Design-Compiler installation directory in environment variable \"PATH\"\n";
	$error_flag=1;
    }

    # Check ModelSim
    my @paths = grep { -x "$_/vsim" } split /:/, $ENV{PATH}, $ENV{path};
    unless ( scalar @paths ) {
	print "\nERROR: ModelSim not available\n";
	print "Include ModelSim installation directory in environment variable \"PATH\"\n";
	$error_flag=1;
    }
}
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
sub usage {
        &version();
        print STDERR <<EOL;

Usage : rtl2gds [Options] [Inputs] [Libraries] [Constraints]

  Options:
    -genScr=<top_dir_name>     : Generate only the scripts and dir structures
                                 in the dir_name. Do not run anything
    -SYNthesis                 : Run synthesis
    -PNR                       : Run Placement and Route
    -SIMulation                : Run simulation
    -POWer                     : Run VCD based power calculation
    -ALL                       : Run synthesis, pnr, simulation and power calculation in the order
    -help                      : Man page for rtl2gds utility
   
  Inputs:
    -rtl=<rtl filename> or <rtl file list(only VHDL)>
    -rtl_top=<rtl top design unit name>
    -tb=<test bench filename>
    -tb_top=<test bench top unit name>
    -lib=<location of LIB directory>
    -tech=<target technology>
   
   Eg.  rtl2gds -rtl=/home/user/rtl/counter.vhd -rtl_top=counter -lib=/usr/local/LIB -tech=tsmc018
   Eg.  rtl2gds -rtl=/home/user/rtl/rtl.list -rtl_top=counter -lib=/usr/local/LIB -tech=tsmc018

  Libraries:
    -lib=<library directory>         
    --lib_db=<db library file (for synthesis)>         
    --lib_tlf=<Timing library file (for pnr .tlf/.lib)>         
    --lib_v=<verilog library file (for simulation)>         
    --lib_lef=<lef library file (for pnr)>         
   
   Eg.  rtl2gds -rtl=/home/user/rtl/counter.vhd -rtl_top=counter -lib=/usr/local/LIB -tech=tsmc018 -genScriptOnly
   Eg.  rtl2gds -pnr -rtl=/home/user/rtl/counter.vhd -rtl_top=counter \
                --lib_lef=/home/LIB/tsmc180.lef --lib_tlf=/home/LIB/tsmc180.tlf

  Supported timing constraints:
    -frequency=<value>  (in MHz)
    -max_area=<value>   (in um2)
    -io_input_delay=<value>  (in ns)
    -io_output_delay=<value> (in ns)
    -clk_latency=<value>     (in ns)
    -clk_uncertainty=<value> (in ns)

    Eg.  rtl2gds -syn \\
        -rtl=/home/users/rtl/counter.vhd -rtl_top=counter -lib=/usr/local/LIB -tech=tsmc018 \\
        -frequency=100 -max_area=0 
    Eg.  rtl2gds -pnr \\
        -rtl_top=counter -lib=/usr/local/LIB -tech=tsmc018 \\
        -frequency=100 -io_output_delay=4 -io_input_delay=4 -clk_uncertainty=1 -clk_latency=3 

Important: Provide full path for files/directories
           Provide RTL2GDSHOME env variable pointing to the installation directory
           --lib_* options take precedence over LIB env variable and -lib option.

          First create the needed directory strucutre and scripts using -genScr option.
          Subsequently individual steps are invoked using -syn/-pnr/-sim/-all options.
          MAN page is available at the TOP-DIR created using -genScr option.
          # man rtl2gds OR 
          # man TOP-DIR/man/rtl2gds.1 (after first time run as "rtl2gds -genScr=. " )
	  OR go through rtl2gds.pdf available at the TOP-DIR (after first time run as "rtl2gds -genScr=. " )

EOL
        exit($stat);
}

#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
sub version {
    print STDERR "\n#######################################################\nrtl2gds - version 4 \nCadence SoC encounter - version 8.1/6.2 \nSynopsys Design Compiler - version 2006.06\nMentor ModelSim - version SE-64 6.2\n#######################################################\n";
    &check_rtl2gdshome();
}

#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
sub help {
    system ("cat $RTL2GDS_INST/man");
    exit(1);           

}

#--------------------------------------
