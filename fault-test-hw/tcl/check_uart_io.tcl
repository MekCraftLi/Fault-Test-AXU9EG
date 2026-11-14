create_project -in_memory -part xczu9eg-ffvb1156-2-i
create_bd_design "axi_bus"
set ps [create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:* zynq_ultra_ps_e_0]
puts "UART0 IO RANGE: [list_property_value CONFIG.PSU__UART0__PERIPHERAL__IO $ps]"
puts "UART1 IO RANGE: [list_property_value CONFIG.PSU__UART1__PERIPHERAL__IO $ps]"
exit
