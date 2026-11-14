open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp

puts "=== Frame commands ==="
puts [help -all *frame*]
puts "=== Essential commands ==="
puts [help -all *essential*]

# Check properties on a tile
set t [get_tiles CLEM_X33Y159]
puts "Properties on $t:"
foreach p [list_property $t] {
    puts "  $p = [get_property $p $t]"
}

# Check properties on a site
set s [get_sites SLICE_X50Y145]
puts "Properties on $s:"
foreach p [list_property $s] {
    puts "  $p = [get_property $p $s]"
}

exit
