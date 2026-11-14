open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp
puts "BITSTREAM.SEU properties:"
foreach p [list_property [current_design] BITSTREAM.SEU.*] {
    puts "   = [get_property  [current_design]]"
}
foreach p [list_property [current_design] *ESSENTIAL*] {
    puts "   = [get_property  [current_design]]"
}
close_project
exit
