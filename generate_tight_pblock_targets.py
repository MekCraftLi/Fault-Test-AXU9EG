#!/usr/bin/env python3
"""
generate_tight_pblock_targets.py
Implements Scheme 2 (strictly replicating 7020 addr-shiyan):
- Focuses strictly on the core physical configuration frames containing TESTMODULE:
  - Frame 17114 (0x0008630c)
  - Frame 17130 (0x0008640c)
  - Frame 17230 (0x0008670c)
  - Frame 17322 (0x0008690c)
  - Frame 17338 (0x00086a0c)
- Extracts ALL 1,973 essential configuration bits (100% full coverage, ZERO sampling/ZERO stride).
- Writes ebd.bin, frameRange.txt, and ebd_table.h for sequential bit-by-bit hardware execution.
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

    all_targets = []
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
                            all_targets.append((val, f_idx, w_idx, b_idx))
                elif f_idx > max(target_frames):
                    break
                wordCnt += 1

    print(f"[Scheme 2] Total 100% full-coverage essential bits extracted: {len(all_targets)}")

    # Write ebd.bin
    with open(ebd_bin_path, "wb") as fb:
        for t in all_targets:
            fb.write(struct.pack("I", t[0]))

    # Write frameRange.txt
    with open(frame_range_path, "w") as ft:
        for t in all_targets:
            ft.write(f"0x{t[0]:08X}\n")

    # Write ebd_table.h
    with open(app_table_path, "w") as f:
        f.write("// Auto-generated Tight PBlock Target Table (Scheme 2: 100% Full Coverage, No Stride)\n")
        f.write(f"// Replicating 7020 addr-shiyan with {len(all_targets)} sequential physical targets\n")
        f.write("#ifndef EBD_TABLE_H\n")
        f.write("#define EBD_TABLE_H\n\n")
        f.write("#include <stdint.h>\n\n")
        f.write(f"constexpr uint32_t PBLOCK_EBD_COUNT = {len(all_targets)};\n\n")
        f.write("struct PBlockTarget {\n")
        f.write("    uint32_t far;\n")
        f.write("    uint16_t frame;\n")
        f.write("    uint8_t  word;\n")
        f.write("    uint8_t  bit;\n")
        f.write("};\n\n")
        f.write(f"static const PBlockTarget PBLOCK_EBD_TARGETS[PBLOCK_EBD_COUNT] = {{\n")
        for t in all_targets:
            f.write(f"    {{0x{t[0]:08X}U, {t[1]}, {t[2]}, {t[3]}}},\n")
        f.write("};\n\n")
        f.write("#endif // EBD_TABLE_H\n")

    frames_covered = len(set(t[1] for t in all_targets))
    print(f"[Scheme 2] Successfully wrote {len(all_targets)} targets across {frames_covered} core frames!")

if __name__ == "__main__":
    main()
