open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp
set dut_cells [get_cells -hierarchical -filter {NAME =~ *dut_inst* && IS_PRIMITIVE == 1}]
puts "DUT PRIMITIVES: [llength $dut_cells]"
foreach c $dut_cells {
    puts "  $c -> [get_property SITE $c]"
}
close_project
exit
