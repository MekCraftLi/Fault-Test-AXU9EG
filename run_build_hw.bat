@echo off
set XILINXD_LICENSE_FILE=C:\Users\Jiaha\AppData\Roaming\XilinxLicense\vivado_lic2037.lic
call C:\Xilinx\Vivado\2022.2\bin\vivado.bat -mode batch -source C:\Project\ZYNQ_test\Fault-Test-AXU9EG\fault-test-hw\tcl\build_hw.tcl -nolog -nojournal
