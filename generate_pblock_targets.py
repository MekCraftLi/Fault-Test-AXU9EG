#!/usr/bin/env python3
"""
generate_pblock_targets.py
Extracts authentic fault injection targets strictly belonging to pblock_TESTMODULE in XCZU9EG:
1. Core datapath & register bits from top.ll (o_data_real, acc_real, acc_imag)
2. Essential LUT & routing configuration bits from top.ebd in the 5 PBlock frames:
   - Frame 17114 (0x0008630c)
   - Frame 17130 (0x0008640c): Datapath, registers & accumulators
   - Frame 17230 (0x0008670c): Complex multipliers
   - Frame 17322 (0x0008690c): Multiplier routing
   - Frame 17338 (0x00086a0c): Interconnect & control

Address format:
  val = ((linear_frame & 0xFFFFF) << 12) | ((word_idx & 0x7F) << 5) | (bit_idx & 0x1F)
"""

import os
import re
import struct

def main():
    base_dir = r"C:\Project\ZYNQ_test\Fault-Test-AXU9EG\fault-test-ps\bsp"
    ll_path = os.path.join(base_dir, "top.ll")
    ebd_path = os.path.join(base_dir, "top.ebd")
    ebd_bin_path = os.path.join(base_dir, "ebd.bin")
    frame_range_path = os.path.join(base_dir, "frameRange.txt")
    app_table_path = r"C:\Project\ZYNQ_test\Fault-Test-AXU9EG\fault-test-ps\application\ebd_table.h"

    target_frames = [17114, 17130, 17230, 17322, 17338]
    target_frames_set = set(target_frames)

    targets = []
    seen = set()

    # 1. First, extract direct register bits from top.ll for TESTMODULE
    with open(ll_path, "r") as f:
        for line in f:
            if "TESTMODULE" in line and "0x0008640c" in line:
                parts = line.split()
                fr_bit = int(parts[3])
                w_idx = fr_bit // 32
                b_idx = fr_bit % 32
                val = ((17130 & 0xFFFFF) << 12) | ((w_idx & 0x7F) << 5) | (b_idx & 0x1F)
                if val not in seen:
                    seen.add(val)
                    targets.append((val, 17130, w_idx, b_idx, "REG:" + parts[-1].split("=")[-1]))

    print(f"[Targets] Extracted {len(targets)} direct register bits from top.ll")

    # 2. Extract essential configuration bits from top.ebd in the 5 PBlock frames
    all_ebd = {f: [] for f in target_frames}
    with open(ebd_path, "r") as f:
        wordCnt = 0
        for line in f:
            line = line.strip()
            if len(line) == 32 and all(c in '01' for c in line):
                f_idx = wordCnt // 93
                w_idx = wordCnt % 93
                if f_idx in target_frames_set:
                    for b_idx in range(32):
                        if line[31 - b_idx] == '1':
                            val = ((f_idx & 0xFFFFF) << 12) | ((w_idx & 0x7F) << 5) | (b_idx & 0x1F)
                            if val not in seen:
                                all_ebd[f_idx].append((val, f_idx, w_idx, b_idx, f"EBD:F{f_idx}_W{w_idx}_B{b_idx}"))
                elif f_idx > max(target_frames):
                    break
                wordCnt += 1

    # Select additional targets from each frame to reach total 128
    # Priority on Frame 17130 (core logic) and Frame 17230 (multipliers)
    needed = 128 - len(targets)
    per_frame_quotas = {
        17130: int(needed * 0.40),
        17230: int(needed * 0.25),
        17114: int(needed * 0.15),
        17322: int(needed * 0.10),
        17338: needed - int(needed * 0.40) - int(needed * 0.25) - int(needed * 0.15) - int(needed * 0.10)
    }

    for f, quota in per_frame_quotas.items():
        pool = all_ebd[f]
        if len(pool) > 0:
            stride = max(1, len(pool) // quota)
            for i in range(min(quota, len(pool))):
                item = pool[i * stride]
                seen.add(item[0])
                targets.append(item)

    print(f"[Targets] Total targets selected: {len(targets)}")

    # Truncate or pad to exactly 128
    targets = targets[:128]

    # Write ebd.bin
    with open(ebd_bin_path, "wb") as fb:
        for t in targets:
            fb.write(struct.pack("I", t[0]))

    # Write frameRange.txt
    with open(frame_range_path, "w") as ft:
        for t in targets:
            ft.write(f"0x{t[0]:08X}\n")

    # Write ebd_table.h
    with open(app_table_path, "w") as f:
        f.write("// Auto-generated Authentic PBlock Fault Injection Targets\n")
        f.write("// Strictly sampled from pblock_TESTMODULE registers (top.ll) and essential bits (top.ebd)\n")
        f.write("#ifndef EBD_TABLE_H\n")
        f.write("#define EBD_TABLE_H\n\n")
        f.write("#include <stdint.h>\n\n")
        f.write(f"constexpr uint32_t PBLOCK_EBD_COUNT = {len(targets)};\n\n")
        f.write("struct PBlockTarget {\n")
        f.write("    uint32_t far;\n")
        f.write("    uint16_t frame;\n")
        f.write("    uint8_t  word;\n")
        f.write("    uint8_t  bit;\n")
        f.write("};\n\n")
        f.write(f"static const PBlockTarget PBLOCK_EBD_TARGETS[PBLOCK_EBD_COUNT] = {{\n")
        for t in targets:
            f.write(f"    {{0x{t[0]:08X}U, {t[1]}, {t[2]}, {t[3]}}},\n")
        f.write("};\n\n")
        f.write("#endif // EBD_TABLE_H\n")

    print("[Targets] Successfully generated ebd.bin, frameRange.txt, and ebd_table.h!")

if __name__ == "__main__":
    main()
