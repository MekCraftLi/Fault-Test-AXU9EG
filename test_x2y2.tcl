open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp
set cr [get_clock_regions X2Y2]
set sl [get_sites -quiet -of_objects $cr -filter {SITE_TYPE =~ SLICE*}]
puts "=== SLICEs in X2Y2: [llength $sl] ==="
puts "First 5: [lrange $sl 0 4]"
puts "Last 5: [lrange $sl end-4 end]"
close_project
exit
