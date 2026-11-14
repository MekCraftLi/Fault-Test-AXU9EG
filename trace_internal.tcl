open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp
set fp [open "command_code_internal.txt" "w"]
for {set i 0} {$i < 44} {incr i} {
    set pin "sem_support_inst/sem_controller/inst/controller/command_code\[$i\]"
    set fanout [get_nodes -of [get_pins $pin] -quiet]
    set cells [get_cells -of [get_pins -leaf -filter {DIRECTION == IN} -of [get_nets -of [get_pins $pin]]] -quiet]
    puts $fp "BIT $i: $cells"
}
close $fp
exit
