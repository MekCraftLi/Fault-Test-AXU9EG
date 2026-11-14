open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp
set cr [get_clock_regions -of_objects [get_sites SLICE_X37Y130]]
puts "=== CLOCK REGION of SLICE_X37Y130: $cr ==="
set sl [get_sites -quiet -of_objects $cr -filter {SITE_TYPE =~ SLICE*}]
puts "=== SLICEs in $cr: [llength $sl] ==="
puts "First 5: [lrange $sl 0 4]"
puts "Last 5: [lrange $sl end-4 end]"
set dsps [get_sites -quiet -of_objects $cr -filter {SITE_TYPE =~ DSP*}]
puts "=== DSPs in $cr: [llength $dsps] sample: [lrange $dsps 0 3] ==="
close_project
exit
