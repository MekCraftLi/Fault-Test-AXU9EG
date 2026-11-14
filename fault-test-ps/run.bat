@echo off
set VITIS_BIN=C:\Xilinx\Vitis\2022.2\bin

tasklist | findstr /i hw_server.exe >nul
if %errorlevel% neq 0 (
    start "" "%VITIS_BIN%\hw_server.bat"
    timeout /t 3 >nul
)

cd /d "%~dp0"
"%VITIS_BIN%\xsdb.bat" "%~dp0run_jtag.tcl"
