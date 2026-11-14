/**
 *******************************************************************************
 * @file    time.hpp
 * @brief   基于 ARM Cortex-A9 Global Timer 的全局高精度时间服务
 *******************************************************************************
 * @author  MekLi
 * @date    2026/11/06
 * @version 1.0
 *******************************************************************************
 */
/* Define to prevent recursive inclusion -----------------------------------------------------------------------------*/

#ifndef ZYNQ_FAULT_TEST_TIME_HPP
#define ZYNQ_FAULT_TEST_TIME_HPP

/*-------- 1. includes and imports -----------------------------------------------------------------------------------*/

/* I. interface */

/* II. OS */

/* III. middlewares */

/* IV. drivers */
#include "xtime_l.h"

/* V. standard lib */
#include <stdint.h>

/*-------- 2. enum ---------------------------------------------------------------------------------------------------*/

/*-------- 3. interface ---------------------------------------------------------------------------------------------*/

namespace utils {

class Time {
public:
    static constexpr uint64_t kTicksPerSecond = COUNTS_PER_SECOND;
    static constexpr uint64_t kTicksPerMs     = kTicksPerSecond / 1000ULL;
    static constexpr uint64_t kTicksPerUs     = kTicksPerSecond / 1000000ULL;

    /**
     * @brief 获取 64 位全局硬件定时器计数值 (单调递增，永不溢出)
     */
    static inline uint64_t getTicks() {
        XTime ticks;
        XTime_GetTime(&ticks);
        return static_cast<uint64_t>(ticks);
    }

    /**
     * @brief 获取系统启动以来的绝对微秒数 (us)
     */
    static inline uint64_t getTimeUs() {
        return getTicks() / kTicksPerUs;
    }

    /**
     * @brief 获取系统启动以来的绝对毫秒数 (ms)
     */
    static inline uint64_t getTimeMs() {
        return getTicks() / kTicksPerMs;
    }

    /**
     * @brief 精确微秒级硬件阻塞延时 (不受编译器优化影响)
     */
    static inline void delayUs(uint32_t us) {
        uint64_t start = getTicks();
        uint64_t delta = static_cast<uint64_t>(us) * kTicksPerUs;
        while ((getTicks() - start) < delta) {
        }
    }

    /**
     * @brief 精确毫秒级硬件阻塞延时
     */
    static inline void delayMs(uint32_t ms) {
        delayUs(ms * 1000U);
    }
};

/**
 * @brief 物理时间确定性超时器 (Deadline Timer)
 */
class Timeout {
private:
    uint64_t deadlineTicks_;

public:
    explicit Timeout(uint32_t timeoutUs) {
        deadlineTicks_ = Time::getTicks() + static_cast<uint64_t>(timeoutUs) * Time::kTicksPerUs;
    }

    static Timeout fromMs(uint32_t milliseconds) {
        return Timeout(milliseconds * 1000U);
    }

    bool isExpired() const {
        return Time::getTicks() >= deadlineTicks_;
    }

    void reset(uint32_t timeoutUs) {
        deadlineTicks_ = Time::getTicks() + static_cast<uint64_t>(timeoutUs) * Time::kTicksPerUs;
    }

};

/**
 * @brief 高精度秒表 (Stopwatch)
 */
class Stopwatch {
private:
    uint64_t startTicks_;

public:
    Stopwatch() : startTicks_(Time::getTicks()) {}

    void restart() {
        startTicks_ = Time::getTicks();
    }

    uint64_t elapsedUs() const {
        return (Time::getTicks() - startTicks_) / Time::kTicksPerUs;
    }

    uint64_t elapsedMs() const {
        return (Time::getTicks() - startTicks_) / Time::kTicksPerMs;
    }
};

} // namespace utils

#endif // ZYNQ_FAULT_TEST_TIME_HPP
