#!/bin/bash 

# LIC settings need to be provided in ~/.bashrc or ~/.cshrc
\rm -rf work
dc_shell-xg-t -f ../scripts/compile_dc.tcl | tee ../logs/synthesis.log
\rm -rf work

