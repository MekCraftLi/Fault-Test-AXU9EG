open_project C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.xpr
set ip [get_ips sem_ultra_0]
puts "=== SEM_ULTRA_0 PROPERTIES ==="
foreach p [list_property $ip] {
    if {[string match "CONFIG.*" $p]} {
        puts "  $p = [get_property $p $ip]"
    }
}
close_project
exit
