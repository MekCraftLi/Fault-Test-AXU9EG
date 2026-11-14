open_project C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.xpr
generate_target {instantiation_template} [get_ips sem_ultra_0]
set veoi [get_files *sem_ultra_0.veo]
puts "=== VEO FILE: $veoi ==="
if {[file exists $veoi]} {
    set fp [open $veoi r]
    puts [read $fp]
    close $fp
}
close_project
exit
