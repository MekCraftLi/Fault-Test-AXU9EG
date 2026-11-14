/**
 *******************************************************************************
 * @file    uart_reporter.hpp
 * @brief   基于串口 (UART / xil_printf) 的轻量级注错结果观察者实现类
 *******************************************************************************
 * @author  MekLi
 * @date    2026/11/10
 * @version 1.0
 *******************************************************************************
 */
/* Define to prevent recursive inclusion -----------------------------------------------------------------------------*/

#ifndef ZYNQ_FAULT_TEST_UART_REPORTER_HPP
#define ZYNQ_FAULT_TEST_UART_REPORTER_HPP

/*-------- 1. includes and imports -----------------------------------------------------------------------------------*/

/* I. interface */
#include "test/itest_reporter.hpp"

/* II. OS */

/* III. middlewares */

/* IV. drivers */
#include "xil_printf.h"

/* V. standard lib */
#include <stdint.h>

/*-------- 2. enum ---------------------------------------------------------------------------------------------------*/

/*-------- 3. class --------------------------------------------------------------------------------------------------*/

/**
 * @brief 串口格式化表格输出观察者
 * @tparam MetricsType 算法自定义度量类型
 */
template <typename MetricsType = EmptyMetrics>
class UartReporter : public ITestReporter<MetricsType> {
public:
    void onTestStart(size_t total_count) override {
        xil_printf("\r\n======================================================================\r\n");
        xil_printf("  [FAULT TEST ENGINE] Starting Injection Run... Total Points: %d\r\n", static_cast<int>(total_count));
        xil_printf("======================================================================\r\n");
        xil_printf("|  Index  |  FAR Address  | BitOff |   Effect    | Recovered | Time (us) |\r\n");
        xil_printf("|---------+---------------+--------+-------------+-----------+-----------|\r\n");
    }

    void onIterationComplete(
        const InjectionRecord<MetricsType>& record,
        size_t current_index,
        size_t total_count
    ) override {
        const char* effect_str = "Unknown";
        switch (record.effect()) {
            case FaultEffect::Silent:        effect_str = "Silent"; break;
            case FaultEffect::Tolerable:     effect_str = "Tolerable"; break;
            case FaultEffect::Intolerable:   effect_str = "Intolerable"; break;
            case FaultEffect::SystemFailure: effect_str = "SysFailure"; break;
        }

        const char* recov_str = record.recovered ? "PASS" : "FAIL";

        xil_printf("| %4d/%-4d |  0x%08X   |  %4d  | %-11s |   %-5s   | %9d |\r\n",
                   static_cast<int>(current_index),
                   static_cast<int>(total_count),
                   record.address.far,
                   record.address.bitOffset,
                   effect_str,
                   recov_str,
                   record.durationUs);
    }

    void onTestFinish(const TestSummary& summary) override {
        xil_printf("======================================================================\r\n");
        xil_printf("  [FAULT TEST SUMMARY REPORT]\r\n");
        xil_printf("----------------------------------------------------------------------\r\n");
        xil_printf("  Total Injected Points : %d\r\n", summary.totalInjections);
        xil_printf("  Silent (No-effect)    : %d\r\n", summary.silentInjections);
        xil_printf("  Tolerable Faults      : %d\r\n", summary.tolerableInjections);
        xil_printf("  Intolerable Errors    : %d\r\n", summary.intolerableInjections);
        xil_printf("  System Failures (Hang): %d\r\n", summary.systemFailureInjections);
        xil_printf("  Recovery Failures     : %d\r\n", summary.recoveryFailures);
        xil_printf("  Total Time Elapsed    : %d us\r\n", summary.totalDurationUs);

        // xil_printf 不支持浮点数，转换为整数+小数两部分格式化输出
        float fatal_rate = summary.fatalFailureRate();
        int fatal_int = static_cast<int>(fatal_rate);
        int fatal_frac = static_cast<int>((fatal_rate - fatal_int) * 100.0f);
        xil_printf("  Fatal Failure Rate    : %d.%02d %%\r\n", fatal_int, fatal_frac);

        float res_rate = summary.resilienceRate();
        int res_int = static_cast<int>(res_rate);
        int res_frac = static_cast<int>((res_rate - res_int) * 100.0f);
        xil_printf("  Task Resilience Rate  : %d.%02d %%\r\n", res_int, res_frac);

        float avg_ms = summary.avgDurationMs();
        int avg_int = static_cast<int>(avg_ms);
        int avg_frac = static_cast<int>((avg_ms - avg_int) * 100.0f);
        xil_printf("  Avg Latency per Point : %d.%02d ms (Target < 100ms)\r\n", avg_int, avg_frac);
        xil_printf("======================================================================\r\n\r\n");
    }
};

#endif // ZYNQ_FAULT_TEST_UART_REPORTER_HPP
