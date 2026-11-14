create_project -in_memory -part xczu9eg-ffvb1156-2-i
create_bd_design "axi_bus"
set ps [create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:* zynq_ultra_ps_e_0]
puts "PS created successfully: $ps"
exit
