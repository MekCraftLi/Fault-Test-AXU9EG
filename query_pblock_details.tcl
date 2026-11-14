open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp

set pblock [get_pblocks pblock_TESTMODULE]
puts "PBlock: $pblock"
set sites [get_sites -of_objects $pblock]
puts "Total sites in pblock: [llength $sites]"

set tiles [get_tiles -of_objects $sites]
puts "Total tiles in pblock: [llength $tiles]"

# Get distinct tile types
set tile_types [lsort -unique [get_property TYPE $tiles]]
puts "Tile types in pblock: $tile_types"

foreach t [lrange $tiles 0 10] {
    puts "Tile: $t | Type: [get_property TYPE $t] | Grid: ([get_property GRID_POINT_X $t], [get_property GRID_POINT_Y $t])"
}

# Group cells by REF_NAME
set cells [get_cells -hier -filter {NAME =~ *TESTMODULE/*}]
set lut_cells [get_cells -hier -filter {NAME =~ *TESTMODULE/* && REF_NAME =~ LUT*}]
set ff_cells [get_cells -hier -filter {NAME =~ *TESTMODULE/* && REF_NAME =~ FD*}]
set dsp_cells [get_cells -hier -filter {NAME =~ *TESTMODULE/* && REF_NAME =~ DSP*}]
puts "TESTMODULE breakdown: LUTs=[llength $lut_cells], FFs=[llength $ff_cells], DSPs=[llength $dsp_cells]"

# Look at some LUT cells and their INIT properties (truth tables)
foreach lc [lrange $lut_cells 0 10] {
    puts "LUT: $lc | Loc: [get_property LOC $lc] | Bel: [get_property BEL $lc] | INIT: [get_property INIT $lc]"
}

exit
