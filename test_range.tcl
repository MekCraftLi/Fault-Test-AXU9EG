open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp
set s [get_sites -quiet {SLICE_X45Y130:SLICE_X50Y150}]
puts "=== SITES COUNT in SLICE_X45Y130:SLICE_X50Y150: [llength $s] ==="
set dsps [get_sites -quiet -of_objects [get_clock_regions X2Y2] -filter {SITE_TYPE =~ DSP*}]
puts "=== DSPs in X2Y2: [llength $dsps] sample: [lrange $dsps 0 3] ==="
close_project
exit
