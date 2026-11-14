set_property BITSTREAM.SEU.ESSENTIALBITS YES [current_design]

set_property DONT_TOUCH true [get_cells TESTMODULE]

create_pblock pblock_TESTMODULE
add_cells_to_pblock [get_pblocks pblock_TESTMODULE] [get_cells [list TESTMODULE]]
resize_pblock [get_pblocks pblock_TESTMODULE] -add {SLICE_X48Y140:SLICE_X53Y159 DSP48E2_X8Y70:DSP48E2_X8Y77}
