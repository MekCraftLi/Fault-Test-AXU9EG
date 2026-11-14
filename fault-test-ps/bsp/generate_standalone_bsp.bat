@echo off
set VITIS_BIN=C:\Xilinx\Vitis\2022.2\bin
cd /d "%~dp0"
"%VITIS_BIN%\xsct.bat" "%~dp0generate_standalone_bsp.tcl"
pause
