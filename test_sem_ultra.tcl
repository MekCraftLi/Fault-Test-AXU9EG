open_project C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.xpr
set ip [create_ip -name sem_ultra -version 3.1 -vendor xilinx.com -library ip -module_name sem_ultra_0]
puts "=== SEM_ULTRA IP CREATED: $ip ==="
puts "Properties of sem_ultra:"
foreach p [list_property $ip] {
    puts "  $p = [get_property $p $ip]"
}
close_project
exit
