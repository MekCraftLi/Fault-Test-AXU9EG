cd [file dirname [file normalize [info script]]]
set proj_dir "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw"

create_project -force fault-test-hw $proj_dir -part xczu9eg-ffvb1156-2-i

# 1. 创建 Block Design
create_bd_design "axi_bus"

# 2. 创建 Zynq UltraScale+ MPSoC 核心
set ps [create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:* zynq_ultra_ps_e_0]

# 配置 PS 核心基本参数 (AXU9EG 核心配置)
set_property -dict [list \
    CONFIG.PSU__USE__M_AXI_GP2 {1} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {100.0} \
    CONFIG.PSU__FPGA_PL0_ENABLE {1} \
    CONFIG.PSU__UART0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__UART0__PERIPHERAL__IO {MIO 42 .. 43} \
    CONFIG.PSU__UART0__BAUD_RATE {115200} \
    CONFIG.PSU__DDRC__ENABLE {1} \
    CONFIG.PSU__DDRC__MEMORY_TYPE {DDR 4} \
    CONFIG.PSU__DDRC__BUS_WIDTH {64 Bit} \
    CONFIG.PSU__DDRC__DRAM_WIDTH {16 Bits} \
    CONFIG.PSU__DDRC__SPEED_BIN {DDR4_2400P} \
    CONFIG.PSU__DDRC__DEVICE_CAPACITY {8192 MBits} \
    CONFIG.PSU__DDRC__ROW_ADDR_COUNT {16} \
    CONFIG.PSU__DDRC__COL_ADDR_COUNT {10} \
    CONFIG.PSU__DDRC__BG_ADDR_COUNT {1} \
    CONFIG.PSU__DDRC__BANK_ADDR_COUNT {2} \
    CONFIG.PSU__DDRC__PARITY_ENABLE {0} \
    CONFIG.PSU__DDRC__ECC {Disabled} \
] $ps

# 3. 创建 AXI BRAM 控制器
set bram_ctrl [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:* axi_bram_ctrl_0]
set_property -dict [list \
    CONFIG.DATA_WIDTH {32} \
    CONFIG.SINGLE_PORT_BRAM {1} \
] $bram_ctrl

# 4. 创建复位模块
set rst_gen [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:* proc_sys_reset_0]

# 5. 连接时钟与复位
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] \
               [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_lpd_aclk] \
               [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
               [get_bd_pins proc_sys_reset_0/slowest_sync_clk]

connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] \
               [get_bd_pins proc_sys_reset_0/ext_reset_in]

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
               [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]

# 6. 连接 AXI 总线
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_LPD] \
                    [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]

# 7. 引出 BRAM 端口与 PL 侧时钟复位
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTA_0
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_ports BRAM_PORTA_0]

create_bd_port -dir O -type clk pl_clk
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_ports pl_clk]

create_bd_port -dir O -type rst pl_rst
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_reset] [get_bd_ports pl_rst]

# 8. 分配地址
assign_bd_address -offset 0x80000000 -range 8K [get_bd_addr_segs {axi_bram_ctrl_0/S_AXI/Mem0}]

# 9. 验证并保存
validate_bd_design
save_bd_design

# 10. 生成 HDL 包装顶层
set bd_file [get_files *axi_bus.bd]
generate_target all $bd_file
make_wrapper -files $bd_file -top
add_files -norecurse "$proj_dir/fault-test-hw.gen/sources_1/bd/axi_bus/hdl/axi_bus_wrapper.v"
update_compile_order -fileset sources_1

# 11. 添加 DUT 与 Top 代码
add_files -norecurse "$proj_dir/src/my_bram_reg.v"
add_files -norecurse "$proj_dir/src/top.v"
set_property top top [current_fileset]
update_compile_order -fileset sources_1

puts "=== BD GENERATION & WRAPPER CREATION SUCCESSFUL! ==="
exit
