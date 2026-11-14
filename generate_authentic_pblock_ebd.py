#!/usr/bin/env python3
"""
generate_authentic_pblock_ebd.py
Extracts 128 authentic essential configuration bit targets strictly belonging to
the 5 physical frames of pblock_TESTMODULE in XCZU9EG:
  - Frame 17114 (0x0008630c)
  - Frame 17130 (0x0008640c): Filter datapath & accumulators
  - Frame 17230 (0x0008670c): Complex multipliers
  - Frame 17322 (0x0008690c): Multiplier routing
  - Frame 17338 (0x00086a0c): Interconnect & control

Address format:
  val = ((linear_frame & 0xFFFFF) << 12) | ((word_idx & 0x7F) << 5) | (bit_idx & 0x1F)
"""

import os
import struct

def main():
    base_dir = r"C:\Project\ZYNQ_test\Fault-Test-AXU9EG\fault-test-ps\bsp"
    ebd_path = os.path.join(base_dir, "top.ebd")
    ebd_bin_path = os.path.join(base_dir, "ebd.bin")
    frame_range_path = os.path.join(base_dir, "frameRange.txt")
    app_table_path = r"C:\Project\ZYNQ_test\Fault-Test-AXU9EG\fault-test-ps\application\ebd_table.h"

    target_frames = [17114, 17130, 17230, 17322, 17338]
    target_frames_set = set(target_frames)

    # 1. Parse top.ebd for all essential bits in the 5 authentic frames
    all_targets_by_frame = {f: [] for f in target_frames}

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
                            all_targets_by_frame[f_idx].append((val, f_idx, w_idx, b_idx))
                elif f_idx > max(target_frames):
                    break
                wordCnt += 1

    total_eb = sum(len(v) for v in all_targets_by_frame.values())
    print(f"[EBD Extraction] Found {total_eb} total essential bits across the 5 TESTMODULE frames.")
    for f in target_frames:
        print(f"  Frame {f}: {len(all_targets_by_frame[f])} bits")

    # 2. Select 128 targets proportionately across all 5 frames
    # Giving extra weight to frame 17130 (core accumulators)
    TARGET_TOTAL = 128
    selected = []
    
    # Target distribution across frames:
    # Frame 17114: 25 bits
    # Frame 17130: 45 bits (Core arithmetic)
    # Frame 17230: 25 bits
    # Frame 17322: 15 bits
    # Frame 17338: 18 bits
    # Total = 128 bits
    distribution = {
        17114: 25,
        17130: 45,
        17230: 25,
        17322: 15,
        17338: 18
    }

    for f in target_frames:
        frame_bits = all_targets_by_frame[f]
        count = distribution[f]
        stride = len(frame_bits) // count
        for i in range(count):
            selected.append(frame_bits[i * stride])

    print(f"[EBD Extraction] Selected {len(selected)} authentic distributed targets across TESTMODULE frames.")

    # 3. Write ebd.bin
    with open(ebd_bin_path, "wb") as fb:
        for t in selected:
            fb.write(struct.pack("I", t[0]))

    # 4. Write frameRange.txt
    with open(frame_range_path, "w") as ft:
        for t in selected:
            ft.write(f"0x{t[0]:08X}\n")

    # 5. Write ebd_table.h
    with open(app_table_path, "w") as f:
        f.write("// Auto-generated Authentic PBlock Essential Configuration Bits Table\n")
        f.write("// Strictly sampled from the 5 physical frames of pblock_TESTMODULE in XCZU9EG\n")
        f.write("#ifndef EBD_TABLE_H\n")
        f.write("#define EBD_TABLE_H\n\n")
        f.write("#include <stdint.h>\n\n")
        f.write(f"constexpr uint32_t PBLOCK_EBD_COUNT = {len(selected)};\n\n")
        f.write("struct PBlockTarget {\n")
        f.write("    uint32_t far;\n")
        f.write("    uint16_t frame;\n")
        f.write("    uint8_t  word;\n")
        f.write("    uint8_t  bit;\n")
        f.write("};\n\n")
        f.write("static const PBlockTarget PBLOCK_EBD_TARGETS[PBLOCK_EBD_COUNT] = {\n")
        for i, t in enumerate(selected):
            val, f_idx, w_idx, b_idx = t
            comma = "," if i < len(selected) - 1 else ""
            f.write(f"    {{0x{val:08X}U, {f_idx}, {w_idx}, {b_idx}}}{comma}\n")
        f.write("};\n\n")
        f.write("#endif // EBD_TABLE_H\n")

    print(f"[EBD Extraction] Successfully wrote {len(selected)} targets to:")
    print(f"  - {ebd_bin_path}")
    print(f"  - {frame_range_path}")
    print(f"  - {app_table_path}")

if __name__ == "__main__":
    main()
