open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp
set pb [create_pblock pblock_TESTMODULE]
resize_pblock $pb -add {SLICE_X20Y100:SLICE_X25Y119 DSP48E2_X2Y40:DSP48E2_X2Y47}
puts "=== PBLOCK SITES: [llength [get_sites -of_objects $pb]] ==="
puts "=== PBLOCK SLICES: [llength [get_sites -of_objects $pb -filter {SITE_TYPE =~ SLICE*}]] ==="
puts "=== PBLOCK DSPS: [llength [get_sites -of_objects $pb -filter {SITE_TYPE =~ DSP*}]] ==="
close_project
exit
