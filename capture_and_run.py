#!/usr/bin/env python3
import time
import threading
import subprocess
import serial
import sys

def reader_thread(ser, stop_event, lines_collected):
    while not stop_event.is_set():
        try:
            line = ser.readline()
            if line:
                decoded = line.decode('utf-8', errors='replace').rstrip('\r\n')
                print(f"[UART COM6] {decoded}", flush=True)
                lines_collected.append(decoded)
                if "EXPERIMENT FINISHED" in decoded:
                    stop_event.set()
        except Exception as e:
            break

def main():
    port = "COM6"
    baud = 115200
    print(f"Opening {port} at {baud} baud...", flush=True)

    try:
        ser = serial.Serial(port, baud, timeout=1.0)
    except Exception as e:
        print(f"Error opening {port}: {e}")
        sys.exit(1)

    ser.reset_input_buffer()
    lines_collected = []
    stop_event = threading.Event()

    t = threading.Thread(target=reader_thread, args=(ser, stop_event, lines_collected), daemon=True)
    t.start()

    print("Launching JTAG Download Script via XSCT...", flush=True)
    xsct_path = r"C:\Xilinx\Vitis\2022.2\bin\xsct.bat"
    jtag_script = r"C:\Project\ZYNQ_test\Fault-Test-AXU9EG\fault-test-ps\run_jtag.tcl"

    res = subprocess.run([xsct_path, jtag_script], capture_output=True, text=True)
    print("=== XSCT Output ===")
    print(res.stdout)
    if res.stderr:
        print("=== XSCT Stderr ===")
        print(res.stderr)

    print("Waiting for UART output from silicon...", flush=True)
    start_time = time.time()
    # Wait up to 90 seconds for injection completion
    while not stop_event.is_set() and (time.time() - start_time < 90):
        time.sleep(0.5)

    stop_event.set()
    ser.close()
    print("Execution complete. Total lines captured:", len(lines_collected))

    # Save complete log to file
    with open(r"C:\Project\ZYNQ_test\Fault-Test-AXU9EG\real_hardware_uart_log.txt", "w", encoding="utf-8") as f:
        for l in lines_collected:
            f.write(l + "\n")

if __name__ == "__main__":
    main()
