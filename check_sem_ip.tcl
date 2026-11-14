open_project C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.xpr
puts "=== SEM IPs in Catalog ==="
foreach ip [get_ipdefs *sem*] {
    puts "  $ip"
}
puts "=== ICAP IPs in Catalog ==="
foreach ip [get_ipdefs *icap*] {
    puts "  $ip"
}
close_project
exit
