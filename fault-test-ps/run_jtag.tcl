cd [file dirname [file normalize [info script]]]

# 1. 连接本地硬件服务器
puts "\[INFO\]: Connecting HW server..."
connect -url tcp:127.0.0.1:3121
puts "\[INFO\]: Success to connect server"
after 500

# 2. 烧录 PL 比特流 (包含 pblock_TESTMODULE 隔离的 filter 和 SEM 控制器)
puts "\[INFO\]: Programming PL Bitstream..."
targets -set -nocase -filter {name =~ "*PL*"}

set bit_file [file normalize "./bsp/top.bit"]
if {[file exists $bit_file]} {
    puts "\[INFO\]: Programming Bitstream File \[$bit_file\]"
    fpga $bit_file
    puts "\[SUCCESS\]: Bitstream programmed successfully!"
} else {
    puts "\[ERR\]: No top.bit found in ./bsp/"
    exit 1
}
after 500

# 3. 初始化 PSU 与 DDR4 控制器
puts "\[INFO\]: Initializing PSU & DDR4 via psu_init.tcl..."
set psu_init_file [file normalize "./bsp/psu_init.tcl"]
if {[file exists $psu_init_file]} {
    targets -set -nocase -filter {name =~ "*PSU*"}
    source $psu_init_file
    psu_init
    psu_post_config
    psu_ps_pl_isolation_removal
    psu_ps_pl_reset_config
    catch {mwr 0xFFCA3008 [expr {[mrd -value 0xFFCA3008] & ~1}]}
    puts "\[SUCCESS\]: PSU & DDR4 initialized successfully, ICAPE3 released to PL!"
} else {
    puts "\[WARN\]: No psu_init.tcl found in ./bsp/"
}
after 500

# 4. 选择 Cortex-A53 #0 并释放复位
puts "\[INFO\]: Halting and resetting Cortex-A53 #0..."
targets -set -nocase -filter {name =~ "*Cortex-A53 #0*"}
catch {rst -processor}
after 500
catch {stop}
after 500
catch {configparams force-mem-access 1}

# 4.1 下载 ebd.bin 到 DDR4 内存 0x20000000
set ebd_file [file normalize "./bsp/ebd.bin"]
if {[file exists $ebd_file]} {
    puts "\[INFO\]: Downloading ebd.bin to DDR4 at 0x20000000 \[$ebd_file\]..."
    catch {dow -data $ebd_file 0x20000000}
    puts "\[SUCCESS\]: ebd.bin loaded into DDR4 successfully!"
}
after 200

# 5. 下载 ELF 到 Cortex-A53 #0 并启动执行
set elf_file [file normalize "./cmake-build-debug-xilinx/application.elf"]
if {[file exists $elf_file]} {
    puts "\[INFO\]: Downloading ELF File \[$elf_file\]"
    dow $elf_file
    puts "\[SUCCESS\]: ELF downloaded! Starting execution..."
    con
} else {
    puts "\[ERR\]: No application.elf found!"
    exit 1
}

puts "\[ALL DONE\]: AXU9EG is now running!"
exit 0
