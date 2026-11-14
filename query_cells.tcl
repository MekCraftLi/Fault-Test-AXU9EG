open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp
set cells [get_cells -hierarchical -filter {IS_PRIMITIVE == 1 && PRIMITIVE_TYPE =~ REGISTER.*}]
puts "TOTAL PRIMITIVE REGS: [llength $cells]"
puts "SAMPLE REG SITES:"
for {set i 0} {$i < 10} {incr i} {
    set c [lindex $cells $i]
    puts "  $c -> [get_property SITE $c]"
}
close_project
exit
