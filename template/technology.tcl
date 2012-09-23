#--------------------------------------------------------------
#  Technology settings
#--------------------------------------------------------------

# Ram memories if available should be included.
set search_path [list . \
		     ${LIBPATH} \
		     ]

set alib_library_analysis_path ${LIBPATH}
set target_library [list \
			${TLIB} \
			]
set synthetic_library [list dw_foundation.sldb]
set link_library [concat [list *] $target_library $synthetic_library ]

define_design_lib WORK -path ./work
set verilogout_show_unconnected_pins "true"
#--------------------------------------------------------------
