open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp

set cells [get_cells -hier -filter {NAME =~ *TESTMODULE/*}]
set sites [lsort -unique [get_sites -of_objects $cells]]
puts "Total occupied sites by TESTMODULE: [llength $sites]"
puts "Occupied sites:"
foreach s $sites {
    set t [get_tiles -of_objects $s]
    puts "  $s ([get_property SITE_TYPE $s]) in tile $t"
}
exit
