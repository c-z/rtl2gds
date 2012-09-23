#!/bin/bash 

# LIC settings need to be provided in ~/.bashrc or ~/.cshrc
\rm -rf work
${DC_tool} -f ../scripts/compile_dc.tcl | tee ../logs/counter4.log
\rm -rf work

