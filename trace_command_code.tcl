open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp
set pins [get_pins -hierarchical -filter {NAME =~ *sem_controller*command_code*}]
foreach p $pins {
    set net [get_nets -of $p]
    puts "$p -> $net"
}
exit
