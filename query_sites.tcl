open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp
set slices [get_sites SLICE*]
puts "TOTAL SLICES: [llength $slices]"
puts "SLICE 0: [lindex $slices 0]"
puts "SLICE 100: [lindex $slices 100]"
puts "SLICE 1000: [lindex $slices 1000]"

set clock_regions [get_clock_regions]
puts "CLOCK REGIONS: $clock_regions"
set cr_first [lindex $clock_regions 0]
puts "SITES IN $cr_first : [llength [get_sites -of_objects [get_clock_regions $cr_first]]]"
puts "SAMPLE SLICES IN $cr_first : [lrange [get_sites -of_objects [get_clock_regions $cr_first] -filter {SITE_TYPE =~ SLICE*}] 0 10]"

close_project
exit
