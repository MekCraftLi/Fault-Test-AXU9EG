open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp
set fp [open "C:/env/antigravity/command_reg_trace.txt" "w"]
for {set i 0} {$i < 44} {incr i} {
    set cell "sem_support_inst/sem_controller/inst/controller/command_reg\[$i\]"
    set q_net [get_nets -quiet -of [get_pins -quiet $cell/Q]]
    if {$q_net ne ""} {
        set loads [get_cells -of [get_pins -leaf -filter {DIRECTION == IN} -of $q_net]]
        puts $fp "command_reg\[$i\] -> $loads"
    } else {
        puts $fp "command_reg\[$i\] -> UNCONNECTED/CONSTANT"
    }
}
close $fp
exit
