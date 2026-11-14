open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp
puts "SLICES COUNT: [llength [get_sites SLICE*]]"
puts "SAMPLE SLICES: [lrange [get_sites SLICE*] 0 10]"
puts "SAMPLE DSP: [lrange [get_sites DSP48E2*] 0 5]"
close_project
exit
