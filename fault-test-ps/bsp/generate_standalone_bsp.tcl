# 1. 获取脚本自身所在绝对路径
set script_work_path [file dirname [file normalize [info script]]]
set target_xsa ""
set bsp_out_dir [file normalize "$script_work_path/standalone_bsp"]

# 2. 检查是否通过命令行传入xsa路径
if {$argc > 0} {
	if {$argc == 1} {
		set input_path [lindex $argv 0]
		set ext [string tolower [file extension $input_path]]
		if {$ext eq ""} {
			set input_path "${input_path}.xsa"
			set ext ".xsa"
		}	
		if {[file exists $input_path]} {
			if {$ext eq ".xsa"} {
				set target_xsa $input_path
			} else {
				puts "\[ERR\]: Format error"
			}
		} else {
			puts "\[ERR\]: File name error"
		}
	} else {
		puts "\[ERR\]: Parameters error"
	}
}

# 3. 自动搜索.xsa文件
if {$target_xsa eq ""} {
	set found_files [list]
	set matched [glob -nocomplain -directory ${script_work_path} -types f "*.xsa"]
	foreach f $matched {
		lappend found_files [file normalize $f]
	}
	if {[llength $found_files] == 0} {
		puts "\[ERR\]: No .xsa file found in $script_work_path"
		exit 1
	} elseif {[llength $found_files] != 1} {
		puts "\[ERR\]: Too many .xsa files"
		exit 1
	} else {
		set target_xsa [lindex $found_files 0]
	}
}

puts "\n\[INFO\]: Found .xsa file \[${target_xsa}\]\n"
puts "\[INFO\]: BSP output path \[${bsp_out_dir}\]\n"

# 4. 调用 HSI 打开硬件设计并生成/编译 UltraScale+ BSP
hsi::open_hw_design $target_xsa
hsi::create_sw_design "standalone_bsp" -os "standalone" -proc "psu_cortexa53_0"
hsi::generate_bsp -dir $bsp_out_dir -compile

puts "\n\[SUCCESS\]: Standalone BSP generate completed!\n"

# 5. 生成 A53 64位 lscript.ld 和 Xilinx.spec
set temp_app_dir [file normalize "$script_work_path/.temp_app"]
hsi::generate_app -app empty_application -proc psu_cortexa53_0 -dir "$temp_app_dir"

if {[file exists "$script_work_path/lscript.ld"]} {
	file delete -force "$script_work_path/lscript.ld"
}
if {[file exists "$script_work_path/Xilinx.spec"]} {
	file delete -force "$script_work_path/Xilinx.spec"
}

file copy "$temp_app_dir/lscript.ld" "$script_work_path/lscript.ld"
file copy "$temp_app_dir/Xilinx.spec" "$script_work_path/Xilinx.spec"
file delete -force "$temp_app_dir"

# 6. 生成并编译 ZynqMP FSBL
hsi::generate_app -app zynqmp_fsbl -proc psu_cortexa53_0 -dir "$script_work_path/fsbl" -compile
if {[file exists "$script_work_path/fsbl/fsbl.elf"]} {
	file delete -force "$script_work_path/fsbl/fsbl.elf"
}
if {[file exists "$script_work_path/fsbl/executable.elf"]} {
	file copy "$script_work_path/fsbl/executable.elf" "$script_work_path/fsbl/fsbl.elf"
}

# 7. 提取 psu_init.tcl 到 bsp 根目录
if {[file exists "$script_work_path/fsbl/psu_init.tcl"]} {
	file copy -force "$script_work_path/fsbl/psu_init.tcl" "$script_work_path/psu_init.tcl"
	puts "\[SUCCESS\]: psu_init.tcl extracted from FSBL!"
}

hsi::close_hw_design [hsi::current_hw_design]
puts "\[SUCCESS\]: ZynqMP FSBL and BSP ready!"
exit 0
