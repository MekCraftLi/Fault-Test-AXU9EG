open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp
set s [get_sites -quiet {SLICE_X20Y100:SLICE_X25Y119}]
puts "Slices count: [llength \]"
set d [get_sites -quiet {DSP48E2_X2Y40:DSP48E2_X2Y47}]
puts "DSP count: [llength \]"
close_project
exit
