open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp

set pb [get_pblocks pblock_TESTMODULE]
puts "PBlock sites: [llength [get_sites -of_objects $pb]]"
puts "PBlock cells: [llength [get_cells -of_objects $pb]]"

set tm_cells [get_cells -hier -filter {NAME =~ *TESTMODULE/*}]
set outside_cells {}
foreach c $tm_cells {
    set s [get_sites -of_objects $c]
    if {$s != "" && [get_pblocks -of_objects $s] != $pb} {
        lappend outside_cells "$c placed at $s"
    }
}
puts "Outside cells count: [llength $outside_cells]"
foreach oc $outside_cells {
    puts "  $oc"
}
exit
