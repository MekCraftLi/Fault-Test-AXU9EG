open_project C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.xpr
puts "=== FILES IN PROJECT ==="
foreach f [get_files] {
    puts "  [get_property NAME $f]"
}
puts "=== IPS IN PROJECT ==="
foreach ip [get_ips] {
    puts "  $ip ([get_property IPDEF $ip])"
}
close_project
exit
