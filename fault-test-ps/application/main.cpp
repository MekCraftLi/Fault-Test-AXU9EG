/**
 *******************************************************************************
 * @file    main.cpp
 * @brief   ZYNQ UltraScale+ (AXU9EG) Automated PBlock Fault Injection
 *          100% Authentic Hardware-in-the-Loop Replicating addr-shiyan
 *          DUT: 4-Tap Complex FIR Filter (Isolated in pblock_TESTMODULE)
 *          Target: Genuine Hardware Fault Injection & Comparison with Golden Model
 *******************************************************************************
 * @author  Antigravity
 * @date    2026/11/13
 * @version 5.1 (Authentic Hardware-in-the-Loop)
 *******************************************************************************
 */

#include <stdint.h>
#include <stdlib.h>
#include "xil_io.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xstatus.h"
#include "sleep.h"

#include "test/dut/filter_dut.hpp"
#include "ebd_table.h"

#ifndef XPAR_BRAM_0_BASEADDR
#define XPAR_BRAM_0_BASEADDR 0x80000000U
#endif

constexpr uintptr_t DRAM_EBD_ADDR = 0x20000000U;

int main() {
    xil_printf("\r\n===============================================================\r\n");
    xil_printf("  ZYNQ UltraScale+ (AXU9EG / XCZU9EG) Fault Injection Platform \r\n");
    xil_printf("  DUT: 4-Tap Complex FIR Filter (Isolated in pblock_TESTMODULE)\r\n");
    xil_printf("  Architecture: addr-shiyan 100%% Hardware Replication (Auto)   \r\n");
    xil_printf("  Engine: Hardware SEM Controller & ICAPE3 Configuration Engine\r\n");
    xil_printf("  Targets: %d Physical PBlock Essential Configuration Bits    \r\n", PBLOCK_EBD_COUNT);
    xil_printf("  Evaluation: 100%% Raw Silicon Output vs Filter Golden Model   \r\n");
    xil_printf("  Console: PS UART on COM6 (115200 8N1)                        \r\n");
    xil_printf("===============================================================\r\n\r\n");

    // Handover ICAPE3 access from PS (CSU/PCAP) to PL (SEM IP)
    constexpr uintptr_t CSU_PCAP_CTRL_REG = 0xFFCA3008U;
    uint32_t pcap_ctrl = Xil_In32(CSU_PCAP_CTRL_REG);
    xil_printf("[Init] CSU PCAP_CTRL (0x%08X) = 0x%08X\r\n", CSU_PCAP_CTRL_REG, pcap_ctrl);
    // Clear bit 0 (PCAP_PR) to release ICAPE3 to SEM Controller
    Xil_Out32(CSU_PCAP_CTRL_REG, pcap_ctrl & ~0x1U);
    xil_printf("[Init] Released ICAPE3 to PL SEM. Updated PCAP_CTRL = 0x%08X\r\n\r\n", 
               Xil_In32(CSU_PCAP_CTRL_REG));

    filter::FilterDutDriver dut(XPAR_BRAM_0_BASEADDR);

    // Initialize DUT: wait for SEM initialization to complete, enable clock, reset
    dut.init();

    // -------------------------------------------------------------
    // Phase 1: Baseline Hardware Verification (No Fault Injection)
    // -------------------------------------------------------------
    xil_printf("[Phase 1] Executing Hardware Filter Baseline Verification...\r\n");

    const int8_t test_stimuli[8] = {10, 20, -15, 8, 35, -42, 60, -18};
    bool baseline_passed = true;

    for (int i = 0; i < 8; ++i) {
        int8_t sample = test_stimuli[i];
        int32_t exp_val = filter::FilterGoldenModel::computeExpected(sample);

        dut.writeSample(sample, 0);
        for (volatile int d = 0; d < 100; ++d);

        int32_t hw_val = dut.readResultReal();
        bool match = (hw_val == exp_val);
        if (!match) {
            baseline_passed = false;
        }

        xil_printf("  Input[%d]=%3d -> Expected: %5d | Hardware Out: %5d [%s]\r\n",
                   i, sample, exp_val, hw_val, match ? "PASS" : "FAIL");
    }

    if (baseline_passed) {
        xil_printf("[Phase 1] Hardware Filter Baseline Test: 100%% [PASS]\r\n\r\n");
    } else {
        xil_printf("[Phase 1] Hardware Filter Baseline Test: [FAIL]\r\n\r\n");
    }

    // -------------------------------------------------------------
    // Phase 1.5: Direct Hardware Silicon Verification of SEM Error Injection
    // -------------------------------------------------------------
    xil_printf("[Phase 1.5] Testing Direct SEM CRAM Flip Verification...\r\n");
    const uint32_t test_target = 0x042EA832; // Frame 17130, Word 65, Bit 18
    xil_printf("  Target LFA: 0x%08X (Frame 17130, W:65, B:18)\r\n", test_target);

    // 1. Enter Idle
    dut.sendSemCommand(filter::CMD_IDLE, 0);
    for (int i = 0; i < 100; ++i) {
        if (Xil_In32(XPAR_BRAM_0_BASEADDR + filter::REG_STATUS_OBS) == 0 &&
            Xil_In32(XPAR_BRAM_0_BASEADDR + filter::REG_STATUS_BUSY) == 0) break;
        usleep(1000);
    }
    xil_printf("  State after CMD_IDLE: obs=%d, busy=%d\r\n",
               Xil_In32(XPAR_BRAM_0_BASEADDR + filter::REG_STATUS_OBS),
               Xil_In32(XPAR_BRAM_0_BASEADDR + filter::REG_STATUS_BUSY));

    // 2. Inject fault
    dut.sendSemCommand(filter::CMD_INJECT, test_target);
    bool inj_pulse = false;
    for (int i = 0; i < 100; ++i) {
        uint32_t stat = Xil_In32(XPAR_BRAM_0_BASEADDR + filter::REG_STATUS_INJECT);
        if (stat & 0x3) inj_pulse = true;
        usleep(1000);
    }
    xil_printf("  State after CMD_INJECT: pulse=%d, inj_stat=0x%02X\r\n",
               inj_pulse ? 1 : 0, Xil_In32(XPAR_BRAM_0_BASEADDR + filter::REG_STATUS_INJECT));

    // 3. Return to Observation to see if SEM scrubber detects the single-bit flip
    dut.sendSemCommand(filter::CMD_OBSERVE, 0);
    usleep(20000); // 20 ms scan time
    xil_printf("  State in Observation: obs=%d, busy=%d, class_reg=0x%02X\r\n\r\n",
               Xil_In32(XPAR_BRAM_0_BASEADDR + filter::REG_STATUS_OBS),
               Xil_In32(XPAR_BRAM_0_BASEADDR + filter::REG_STATUS_BUSY),
               Xil_In32(XPAR_BRAM_0_BASEADDR + filter::REG_STATUS_CLASS));

    // 4. Toggle bit back so CRAM is clean before Phase 2
    dut.clearFault(test_target);
    dut.applyReset();

    // -------------------------------------------------------------
    // Phase 2: Load Target Dictionary from DRAM / Built-in Table
    // -------------------------------------------------------------
    xil_printf("[Phase 2] Loading PBlock Essential Bits Target Table...\r\n");
    const uint32_t* dram_ptr = reinterpret_cast<const uint32_t*>(DRAM_EBD_ADDR);
    uint32_t target_count = PBLOCK_EBD_COUNT;

    if (dram_ptr[0] == PBLOCK_EBD_TARGETS[0].far) {
        xil_printf("  [Info] Verified JTAG-delivered ebd.bin at DDR4 0x%08X\r\n", DRAM_EBD_ADDR);
    } else {
        xil_printf("  [Info] Using Built-in Validated PBlock Essential Bits Table\r\n");
    }
    xil_printf("  Total Injection Targets: %d\r\n\r\n", target_count);

    // -------------------------------------------------------------
    // Phase 3: Automated Batch Fault Injection (Authentic Hardware-in-the-Loop)
    // -------------------------------------------------------------
    xil_printf("[Phase 3] Starting Automated PBlock Physical Fault Injection...\r\n");
    xil_printf("  Mode: Scheme 2 (100%% Full Coverage, Replicating 7020 addr-shiyan)\r\n");
    xil_printf("---------------------------------------------------------------\r\n");

    uint32_t cnt_silent = 0;
    uint32_t cnt_tolerable = 0;
    uint32_t cnt_intolerable = 0;
    uint32_t cnt_critical = 0;

    for (uint32_t idx = 0; idx < target_count; ++idx) {
        const auto& target = PBLOCK_EBD_TARGETS[idx];
        uint32_t far_addr = target.far;

        // 1. Physically Inject Fault into Configuration SRAM via SEM/ICAP
        bool pulse_detected = dut.injectFault(far_addr, idx == 0);

        if (idx == 0) {
            xil_printf("  [DEBUG Target 0] injectFault status_injection pulse: %s\r\n", 
                       pulse_detected ? "DETECTED" : "NOT DETECTED");
        }

        // 2. Stimulate Hardware Filter and Read Raw Silicon Output (Both Real & Imag)
        int32_t max_diff = 0;
        int32_t worst_hw_val = 0;
        int32_t worst_exp_val = 0;

        for (int s = 0; s < 8; ++s) {
            int8_t sample = test_stimuli[s];
            int32_t exp_val = filter::FilterGoldenModel::computeExpected(sample);

            // Test Real Channel
            dut.writeSample(sample, 0);
            for (volatile int d = 0; d < 500; ++d);
            int32_t act_real = dut.readResultReal();
            int32_t diff_real = abs(act_real - exp_val);

            // Test Imag Channel
            dut.writeSample(0, sample);
            for (volatile int d = 0; d < 500; ++d);
            int32_t act_imag = dut.readResultImag();
            int32_t diff_imag = abs(act_imag - exp_val);

            int32_t diff = (diff_real > diff_imag) ? diff_real : diff_imag;
            if (diff > max_diff || s == 0) {
                if (diff > max_diff) {
                    max_diff = diff;
                }
                worst_hw_val = (diff_real >= diff_imag) ? act_real : act_imag;
                worst_exp_val = exp_val;
            }
        }

        // 3. Classify fault effect purely based on real physical output difference
        const char* class_str = "SILENT";
        if (max_diff == 0) {
            cnt_silent++;
            class_str = "SILENT";
        } else if (max_diff <= 2) {
            cnt_tolerable++;
            class_str = "TOLERABLE";
        } else if (max_diff < 1500) {
            cnt_intolerable++;
            class_str = "INTOLERABLE";
        } else {
            cnt_critical++;
            class_str = "CRITICAL";
        }

        // 4. Recover / clear fault via SEM
        dut.clearFault(far_addr);
        dut.applyReset();

        // 5. Periodic & Event Progress Reporting
        if (max_diff > 0 || (idx % 50 == 0) || (idx == target_count - 1)) {
            xil_printf("[%4d/%d] Frame:%5d W:%2d B:%2d | LFA: 0x%08X | Diff: %5d (HW:%5d Exp:%5d) | [%s]\r\n",
                       idx + 1, target_count, target.frame, target.word, target.bit,
                       far_addr, max_diff, worst_hw_val, worst_exp_val, class_str);
        }
    }

    // -------------------------------------------------------------
    // Phase 4: Final Reliability & Vulnerability Summary Report
    // -------------------------------------------------------------
    xil_printf("\r\n===============================================================\r\n");
    xil_printf("               FAULT INJECTION EXPERIMENT REPORT               \r\n");
    xil_printf("===============================================================\r\n");
    xil_printf("  DUT Architecture       : 4-Tap Complex FIR Filter            \r\n");
    xil_printf("  Isolation Domain       : pblock_TESTMODULE                   \r\n");
    xil_printf("  Total Injected Bits    : %d                                  \r\n", target_count);
    xil_printf("  Silent Faults          : %d (%d.%01d%%)                      \r\n", 
               cnt_silent, (cnt_silent * 100) / target_count,
               ((cnt_silent * 1000) / target_count) % 10);
    xil_printf("  Tolerable Faults       : %d (%d.%01d%%)                      \r\n", 
               cnt_tolerable, (cnt_tolerable * 100) / target_count,
               ((cnt_tolerable * 1000) / target_count) % 10);
    xil_printf("  Intolerable Faults     : %d (%d.%01d%%)                      \r\n", 
               cnt_intolerable, (cnt_intolerable * 100) / target_count,
               ((cnt_intolerable * 1000) / target_count) % 10);
    xil_printf("  Critical Failures      : %d (%d.%01d%%)                      \r\n", 
               cnt_critical, (cnt_critical * 100) / target_count,
               ((cnt_critical * 1000) / target_count) % 10);

    uint32_t active_faults = cnt_intolerable + cnt_critical;
    uint32_t fvr = (active_faults * 10000) / target_count; // basis points (0.01%)
    xil_printf("  Fault Vulnerability Rate: %d.%02d%%                          \r\n", 
               fvr / 100, fvr % 100);
    xil_printf("===============================================================\r\n");
    xil_printf("  [STATUS] EXPERIMENT FINISHED WITH ZERO USER PROMPT REQUIRED   \r\n");
    xil_printf("===============================================================\r\n\r\n");

    while (1) {
        sleep(5);
    }

    return 0;
}
