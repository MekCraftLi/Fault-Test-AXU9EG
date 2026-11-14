open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp
set pb [create_pblock pblock_TESTMODULE]
resize_pblock $pb -add {SLICE_X48Y140:SLICE_X53Y159 DSP48E2_X8Y70:DSP48E2_X8Y77}
set sl [get_sites -of_objects $pb -filter {SITE_TYPE =~ SLICE*}]
set ds [get_sites -of_objects $pb -filter {SITE_TYPE =~ DSP*}]
puts "=== VALIDATED PBLOCK: [llength $sl] SLICEs, [llength $ds] DSPs ==="
close_project
exit
