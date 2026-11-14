open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp
set cells [get_cells -hier -filter {NAME =~ *TESTMODULE*}]
puts "Total cells in TESTMODULE: [llength $cells]"
foreach c [lrange $cells 0 30] {
    puts "Cell: $c | Ref: [get_property REF_NAME $c] | Loc: [get_property LOC $c]"
}
exit
