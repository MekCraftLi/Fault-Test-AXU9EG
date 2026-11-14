/**
 *******************************************************************************
 * @file    filter_dut.hpp
 * @brief   FIR Filter Device Under Test (DUT) Driver & Golden Model
 *          Faithfully replicated from addr-shiyan (filter.v + complexMult.v)
 *          Integrated with authentic bram_ctrl.v and SEM controller.
 *******************************************************************************
 */

#ifndef ZYNQ_FAULT_TEST_FILTER_DUT_HPP
#define ZYNQ_FAULT_TEST_FILTER_DUT_HPP

#include <stdint.h>
#include <stdlib.h>
#include "xil_io.h"
#include "xil_printf.h"
#include "sleep.h"

namespace filter {

// Register Offsets from bram_ctrl.v (addr-shiyan)
// Base Address: XPAR_BRAM_0_BASEADDR (0x80000000)
constexpr uint32_t REG_VERSION         = 0x00; // 0x20200306
constexpr uint32_t REG_EXE_CYC_LEN     = 0x04; // execution_cyc_length
constexpr uint32_t REG_INJECT_CYCLE    = 0x08; // inject_cycle
constexpr uint32_t REG_IA_UPPER        = 0x0C; // ia_upper [7:0]
constexpr uint32_t REG_IA_LOWER        = 0x10; // ia_lower [31:0]
constexpr uint32_t REG_ICAP_GRANT      = 0x14; // icap_grant
constexpr uint32_t REG_ICAP_SEL        = 0x18; // icap_sel
constexpr uint32_t REG_INJECT_ENABLE   = 0x1C; // inject_enable
constexpr uint32_t REG_INJECT_STROBE   = 0x20; // inject_strobe
constexpr uint32_t REG_MASK_EXP        = 0x24; // mask_exp
constexpr uint32_t REG_MASK_INJ        = 0x28; // mask_inj
constexpr uint32_t REG_HALT_CLK        = 0x2C; // halt_from_processor (single-beat step)
constexpr uint32_t REG_GSR             = 0x30; // gsr
constexpr uint32_t REG_RESET_RTL       = 0x34; // reset_rtl (active high)
constexpr uint32_t REG_SEM_CLK_EN      = 0x38; // sem_clk_en
constexpr uint32_t REG_EXPIRED_CYC     = 0x3C; // expired_cycle (input)
constexpr uint32_t REG_DUT_CLK_STOPPED = 0x40; // dut_clock_stopped (input)
constexpr uint32_t REG_ERROR           = 0x44; // error (input)
constexpr uint32_t REG_CURRENT_CYC     = 0x48; // current_cycle (input)
constexpr uint32_t REG_INJ_CYC_REACHED = 0x4C; // inject_cycle_reached (input)
constexpr uint32_t REG_STATUS_INJECT   = 0x50; // status_injection (input)
constexpr uint32_t REG_STATUS_INIT     = 0x60; // status_initialization (input)
constexpr uint32_t REG_STATUS_OBS      = 0x64; // status_observation (input)
constexpr uint32_t REG_STATUS_BUSY     = 0x68; // command_busy (input)
constexpr uint32_t REG_CONTINUE_RUN    = 0x6C; // continue_run (offset 27*4 = 0x6C)
constexpr uint32_t REG_STATUS_CLASS    = 0x70; // {uncorrectable, essential, classification, correction}

// DUT Data Register Offsets
constexpr uint32_t REG_DATA_REAL       = 0x80; // i_data_real [7:0]
constexpr uint32_t REG_DATA_IMAG       = 0x84; // i_data_imag [7:0]
constexpr uint32_t REG_RSLT_REAL       = 0x88; // filtRslt_real [17:0]
constexpr uint32_t REG_RSLT_IMAG       = 0x8C; // filtRslt_imag [17:0]

// SEM Commands (addr-shiyan)
constexpr uint32_t CMD_IDLE            = 0xE0;
constexpr uint32_t CMD_INJECT          = 0xC0;
constexpr uint32_t CMD_OBSERVE         = 0xA0;
constexpr uint32_t CMD_RESET           = 0xB0;

enum class FaultClassification {
    SILENT,       // 无偏差 (未使用的PBlock布线或非关键位)
    TOLERABLE,    // 轻微偏差 (|diff| <= 2 LSBs)
    INTOLERABLE,  // 严重失真 (|diff| > 2)
    CRITICAL      // 致命故障 (符号位翻转或饱和)
};

class FilterDutDriver {
public:
    explicit FilterDutDriver(uintptr_t base_addr) : m_base(base_addr) {}

    void init() {
        // Master enable injection interface
        Xil_Out32(m_base + REG_INJECT_ENABLE, 1);

        // Wait for SEM UltraScale+ startup/initialization to complete (status_initialization -> 0)
        xil_printf("  [SEM] Waiting for SEM Controller Initialization...\r\n");
        for (int i = 0; i < 200; ++i) {
            uint32_t init_stat = Xil_In32(m_base + REG_STATUS_INIT);
            if (init_stat == 0 && i >= 10) {
                break;
            }
            usleep(5000);
        }

        uint32_t init_stat = Xil_In32(m_base + REG_STATUS_INIT);
        uint32_t obs_stat  = Xil_In32(m_base + REG_STATUS_OBS);
        uint32_t busy_stat = Xil_In32(m_base + REG_STATUS_BUSY);
        xil_printf("  [SEM] Initial Status: init=%d, obs=%d, busy=%d\r\n",
                   init_stat, obs_stat, busy_stat);

        setContinuousRun(true);
        applyReset();
    }

    void applyReset() {
        Xil_Out32(m_base + REG_RESET_RTL, 1);
        for (volatile int d = 0; d < 100; ++d);
        Xil_Out32(m_base + REG_RESET_RTL, 0);
        for (volatile int d = 0; d < 100; ++d);
    }

    void setContinuousRun(bool enable) {
        Xil_Out32(m_base + REG_CONTINUE_RUN, enable ? 1 : 0);
    }

    void stepClock() {
        Xil_Out32(m_base + REG_HALT_CLK, 1);
        for (volatile int d = 0; d < 10; ++d);
        Xil_Out32(m_base + REG_HALT_CLK, 0);
        for (volatile int d = 0; d < 10; ++d);
    }

    void writeSample(int8_t real, int8_t imag = 0) {
        Xil_Out32(m_base + REG_DATA_REAL, static_cast<uint32_t>(static_cast<uint8_t>(real)));
        Xil_Out32(m_base + REG_DATA_IMAG, static_cast<uint32_t>(static_cast<uint8_t>(imag)));
    }

    int32_t readResultReal() {
        uint32_t raw = Xil_In32(m_base + REG_RSLT_REAL);
        // 18位有符号数符号扩展到32位
        if (raw & 0x00020000U) {
            return static_cast<int32_t>(raw | 0xFFFC0000U);
        }
        return static_cast<int32_t>(raw & 0x0003FFFFU);
    }

    int32_t readResultImag() {
        uint32_t raw = Xil_In32(m_base + REG_RSLT_IMAG);
        if (raw & 0x00020000U) {
            return static_cast<int32_t>(raw | 0xFFFC0000U);
        }
        return static_cast<int32_t>(raw & 0x0003FFFFU);
    }

    void sendSemCommand(uint8_t cmd, uint32_t arg) {
        Xil_Out32(m_base + REG_INJECT_ENABLE, 1);
        Xil_Out32(m_base + REG_IA_LOWER, arg);
        Xil_Out32(m_base + REG_IA_UPPER, static_cast<uint32_t>(cmd));
        usleep(100);
        Xil_Out32(m_base + REG_INJECT_STROBE, 1);
        usleep(100);
        Xil_Out32(m_base + REG_INJECT_STROBE, 0);
        usleep(100);
    }

    // Authentic SEM Fault Injection via SEM parallel command interface
    // Replicating SEMInject() and status_injection handshake from addr-shiyan helloworld.c
    bool injectFault(uint32_t far_val, bool debug = false) {
        if (debug) {
            xil_printf("  [DEBUG Target 0] Pre-Idle: obs=%d, busy=%d, init=%d\r\n",
                       Xil_In32(m_base + REG_STATUS_OBS),
                       Xil_In32(m_base + REG_STATUS_BUSY),
                       Xil_In32(m_base + REG_STATUS_INIT));
        }

        // 1. Enter Idle State (0xE0)
        for (int i = 0; i < 50; ++i) {
            if (Xil_In32(m_base + REG_STATUS_BUSY) == 0) break;
            usleep(1000);
        }
        sendSemCommand(CMD_IDLE, 0);

        // Wait until SEM confirms exit from Observation and enters Idle
        for (int i = 0; i < 100; ++i) {
            if (Xil_In32(m_base + REG_STATUS_OBS) == 0 && Xil_In32(m_base + REG_STATUS_BUSY) == 0) break;
            usleep(1000);
        }

        if (debug) {
            xil_printf("  [DEBUG Target 0] Post-Idle: obs=%d, busy=%d, init=%d\r\n",
                       Xil_In32(m_base + REG_STATUS_OBS),
                       Xil_In32(m_base + REG_STATUS_BUSY),
                       Xil_In32(m_base + REG_STATUS_INIT));
        }

        // 2. Error Injection at target linear frame address (0xC0)
        sendSemCommand(CMD_INJECT, far_val);

        if (debug) {
            xil_printf("  [DEBUG Target 0] Post-Inject send: obs=%d, busy=%d, inj=%d\r\n",
                       Xil_In32(m_base + REG_STATUS_OBS),
                       Xil_In32(m_base + REG_STATUS_BUSY),
                       Xil_In32(m_base + REG_STATUS_INJECT));
        }

        // 3. Wait for SEM Injection Execution via status_injection line (addr-shiyan)
        bool saw_pulse = false;
        for (int retry = 0; retry < 150; ++retry) {
            uint32_t inj_stat = Xil_In32(m_base + REG_STATUS_INJECT);
            if ((inj_stat & 0x3) != 0) {
                saw_pulse = true;
            }
            if (saw_pulse && (inj_stat & 0x1) == 0) {
                break;
            }
            usleep(1000); // 1 ms poll interval
        }

        if (debug) {
            xil_printf("  [DEBUG Target 0] Poll result: saw_pulse=%d, inj_stat=0x%02X, busy=%d, class=0x%02X\r\n",
                       saw_pulse ? 1 : 0, Xil_In32(m_base + REG_STATUS_INJECT), 
                       Xil_In32(m_base + REG_STATUS_BUSY), Xil_In32(m_base + REG_STATUS_CLASS));
        }

        // Additional safeguard wait for ICAP operation
        usleep(5000);

        // NOTE: Keep SEM in Idle state while stimulating DUT!
        // In UltraScale+, Feature Set 4 includes Mitigation and Testing.
        // Returning to Observation causes the SEM background scanner to immediately
        // auto-correct the injected CRAM fault before DUT stimulus can be evaluated!
        // (Matching addr-shiyan helloworld.c line 673 where SEMObservation() was commented out)

        return saw_pulse;
    }

    // Fault Recovery: Invert bit back in Idle, then resume Observation
    void clearFault(uint32_t far_val) {
        // 1. Ensure in Idle
        if (Xil_In32(m_base + REG_STATUS_OBS) != 0) {
            sendSemCommand(CMD_IDLE, 0);
            for (int i = 0; i < 100; ++i) {
                if (Xil_In32(m_base + REG_STATUS_OBS) == 0 && Xil_In32(m_base + REG_STATUS_BUSY) == 0) break;
                usleep(1000);
            }
        }

        // 2. Toggle bit back by injecting same address in Idle
        sendSemCommand(CMD_INJECT, far_val);
        bool saw_pulse = false;
        for (int retry = 0; retry < 150; ++retry) {
            uint32_t inj_stat = Xil_In32(m_base + REG_STATUS_INJECT);
            if ((inj_stat & 0x3) != 0) {
                saw_pulse = true;
            }
            if (saw_pulse && (inj_stat & 0x1) == 0) {
                break;
            }
            usleep(1000);
        }
        usleep(5000);

        // 3. Return to Observation (0xA0) to let SEM confirm CRAM integrity
        sendSemCommand(CMD_OBSERVE, 0);
        for (int i = 0; i < 100; ++i) {
            if (Xil_In32(m_base + REG_STATUS_OBS) == 1) break;
            usleep(1000);
        }
    }

private:
    uintptr_t m_base;
};

// 滤波器硬件 Golden 模型 (稳态增益为 sum(H) = -6 + 123 + 11 - 1 = 127)
class FilterGoldenModel {
public:
    static int32_t computeExpected(int8_t x) {
        return 127 * static_cast<int32_t>(x);
    }
};

} // namespace filter

#endif // ZYNQ_FAULT_TEST_FILTER_DUT_HPP
