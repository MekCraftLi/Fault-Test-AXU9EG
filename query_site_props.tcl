open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp

set s [get_sites SLICE_X50Y145]
puts "Site $s properties:"
foreach p [list_property $s] {
    puts "  $p = [get_property $p $s]"
}

set t [get_tiles -of_objects $s]
puts "Tile $t properties:"
foreach p [list_property $t] {
    puts "  $p = [get_property $p $t]"
}

exit
