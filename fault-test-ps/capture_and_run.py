import subprocess
import threading
import time
import serial

captured_lines = []
stop_event = threading.Event()

def reader_thread():
    try:
        ser = serial.Serial('COM6', 115200, timeout=0.2)
        print("[Serial] COM6 connected at 115200 baud.")
        while not stop_event.is_set():
            line = ser.readline()
            if line:
                decoded = line.decode('utf-8', errors='replace').strip()
                if decoded:
                    captured_lines.append(decoded)
                    print(f"[UART Output] {decoded}")
                    if "EXPERIMENT FINISHED" in decoded:
                        time.sleep(1)
                        stop_event.set()
                        break
        ser.close()
    except Exception as e:
        print(f"[Serial Error]: {e}")

# 1. 启动串口监听线程
t = threading.Thread(target=reader_thread, daemon=True)
t.start()
time.sleep(0.5)

# 2. 执行 JTAG 下载
xsdb_cmd = [
    r"C:\Xilinx\Vitis\2022.2\bin\xsdb.bat",
    r"C:\Project\ZYNQ_test\Fault-Test-AXU9EG\fault-test-ps\run_jtag.tcl"
]

print("[XSDB] Executing JTAG programming & launch...")
res = subprocess.run(xsdb_cmd, capture_output=True, text=True, cwd=r"C:\Project\ZYNQ_test\Fault-Test-AXU9EG\fault-test-ps")
print("[XSDB STDOUT]:\n" + res.stdout)
if res.stderr:
    print("[XSDB STDERR]:\n" + res.stderr)

# 3. 监听串口直到注错完成或达到超时
print("[Monitor] Waiting for automated batch injection to complete on COM6...")
start_time = time.time()
while not stop_event.is_set() and (time.time() - start_time < 30):
    time.sleep(0.5)

stop_event.set()
t.join(timeout=2)

print("\n================ EXPERIMENT SUMMARY ================")
print(f"Total serial lines captured: {len(captured_lines)}")
for l in captured_lines:
    print("  " + l)
print("====================================================\n")
