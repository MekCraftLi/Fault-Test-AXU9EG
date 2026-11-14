open_project C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.xpr

# Enable maximum multi-threading across all logical cores (16 logical processors)
catch {set_param general.maxThreads 16}
puts "=== MAX THREADS CONFIGURED: [get_param general.maxThreads] ==="

# Remove old my_bram_reg if present
set old_reg [get_files -quiet "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/my_bram_reg.v"]
if {[llength $old_reg] > 0} {
    puts "Removing obsolete file: $old_reg"
    remove_files $old_reg
}

# Add all required hardware source files
set files_to_add [list \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/filter.v" \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/complexMult.v" \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/bram_ctrl.v" \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/fim.v" \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/CEM.v" \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/genflag.v" \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/dutcyclecounter.v" \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/level2pulse.v" \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/sem_ultra_0_support.v" \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/sem_ultra_0_cfg.v" \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/sem_ultra_0_uart.v" \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/sem_ultra_0_uart_fifo.v" \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/sem_ultra_0_uart_piso.v" \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/sem_ultra_0_uart_sipo.v" \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/top.v" \
    "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/pblock.xdc" \
]

foreach f $files_to_add {
    if {[llength [get_files -quiet $f]] == 0} {
        puts "Adding file: $f"
        add_files -norecurse $f
    } else {
        puts "File already present: $f"
    }
}

# Ensure pblock.xdc is active
set_property used_in_synthesis true [get_files -quiet "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/pblock.xdc"]
set_property used_in_implementation true [get_files -quiet "C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/src/pblock.xdc"]

# Set top module
set_property top top [current_fileset]
update_compile_order -fileset sources_1

puts "=== PROJECT SOURCES COMPILE ORDER ==="
foreach f [get_files -filter {FILE_TYPE == "Verilog" || FILE_TYPE == "SystemVerilog"}] {
    puts "  [get_property NAME $f]"
}

# Run synthesis with full CPU threads
reset_run synth_1
launch_runs synth_1 -jobs 16
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "=== SYNTHESIS STATUS: $synth_status ==="

if {$synth_status == "synth_design Complete!"} {
    # Run implementation & bitstream with full CPU threads
    reset_run impl_1
    launch_runs impl_1 -to_step write_bitstream -jobs 16
    wait_on_run impl_1
    set impl_status [get_property STATUS [get_runs impl_1]]
    puts "=== IMPLEMENTATION STATUS: $impl_status ==="

    file mkdir C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-ps/bsp
    write_hw_platform -fixed -include_bit -force -file C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-ps/bsp/top.xsa

    # Open implemented design to write logic location file and ensure ebd/ll are generated
    open_run impl_1
    write_bitstream -force -logic_location_file C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-ps/bsp/top.bit

    # Copy all generated ebd, ll, bit files to bsp
    foreach ext {"*.bit" "*.ebd" "*.ll" "*.ebc"} {
        set found [glob -nocomplain -directory C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1 -types f $ext]
        foreach src $found {
            file copy -force $src C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-ps/bsp/
            puts "Copied $src to bsp"
        }
    }
    puts "=== HARDWARE BUILD & BITSTREAM GENERATION COMPLETE ==="
} else {
    puts "=== SYNTHESIS FAILED ==="
}

close_project
exit
