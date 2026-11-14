/**
 *******************************************************************************
 * @file    test_types.hpp
 * @brief   简要描述
 *******************************************************************************
 * @attention
 *
 * none
 *
 *******************************************************************************
 * @note
 *
 * none
 *
 *******************************************************************************
 * @author  MekLi
 * @date    2026/11/09
 * @version 1.0
 *******************************************************************************
 */
/* Define to prevent recursive inclusion -----------------------------------------------------------------------------*/

#ifndef ZYNQ_FAULT_TEST_TEST_TYPE_HPP
#define ZYNQ_FAULT_TEST_TEST_TYPE_HPP
/*-------- 1. includes and imports -----------------------------------------------------------------------------------*/


/* I. interface */

/* II. OS */

/* III. middlewares */

/* IV. drivers */

/* V. standard lib */
#include <stdint.h>


/*-------- 2. enum ---------------------------------------------------------------------------------------------------*/

/**
 * @brief 注错结果
 */
enum class FaultEffect : uint8_t {
    Silent        = 0,
    Tolerable     = 1,
    Intolerable   = 2,
    SystemFailure = 3,
};

/**
 * @brief 注错地址数据类型
 */
struct FaultAddress {
    uint32_t far{0};        // 物理帧地址
    uint16_t bitOffset{0};  // 帧内部的比特偏移
    uint32_t linearAddr{0}; // 线性地址

    FaultAddress() = default;
    FaultAddress(uint32_t f, uint16_t b, uint32_t l) : far{f}, bitOffset{b}, linearAddr{l} {}
};


/**
 * @brief 最后注错的分析结果类型
 * @tparam MetricsType 注错定性统计结果
 */
template <typename MetricsType> struct EvaluationResult {
    FaultEffect effect{FaultEffect::Silent};
    MetricsType metrics;

    EvaluationResult() = default;
    EvaluationResult(FaultEffect e, const MetricsType& m) : effect{e}, metrics{m} {}
};

/**
 * @brief 空度量类型
 */
struct EmptyMetrics {};

template <typename MetricsType> struct InjectionRecord {
    FaultAddress address; // 故障注入的物理和逻辑位置
    EvaluationResult<MetricsType> evalResult;
    uint32_t durationUs{0};
    bool recovered{false};

    FaultEffect effect() const { return evalResult.effect; }
    const MetricsType& metrics() const { return evalResult.metrics; }
};


struct TestSummary {
    uint32_t totalInjections{0}; // 总测试注入数
    uint32_t silentInjections{0};
    uint32_t tolerableInjections{0};
    uint32_t intolerableInjections{0};
    uint32_t systemFailureInjections{0};

    uint32_t recoveryFailures{0}; // 故障的恢复失败次数
    uint32_t totalDurationUs{0};  // 总耗时（微秒）


    /**
     * @brief 记录结果
     * @param e 注错效果
     * @param us 消耗时间（微妙）
     * @param r 是否可恢复
     */
    void record(FaultEffect e, uint32_t us, bool r) {
        totalInjections++;
        totalDurationUs += us;

        if (!r) {
            recoveryFailures++;
        }

        switch (e) {
            case FaultEffect::Silent:
                silentInjections++;
                break;
            case FaultEffect::Tolerable:
                tolerableInjections++;
                break;
            case FaultEffect::Intolerable:
                intolerableInjections++;
                break;
            case FaultEffect::SystemFailure:
                systemFailureInjections++;
                break;
        }
    }


    /// @brief 致命故障率 (Fatal Failure Rate, %): (不可容忍 + 系统瘫痪) / 总数
    float fatalFailureRate() const {
        if (totalInjections == 0)
            return 0.0f;
        return static_cast<float>(intolerableInjections + systemFailureInjections) / totalInjections * 100.0f;
    }
    /// @brief 任务弹性率 (Resilience Rate, %): (静默 + 可容忍) / 总数
    float resilienceRate() const {
        if (totalInjections == 0)
            return 0.0f;
        return static_cast<float>(silentInjections + tolerableInjections) / totalInjections * 100.0f;
    }
    /// @brief 平均单点测试耗时 (毫秒, ms), 用于验证是否 < 100 ms
    float avgDurationMs() const {
        if (totalInjections == 0)
            return 0.0f;
        return static_cast<float>(totalDurationUs) / (totalInjections * 1000.0f);
    }
};


/*-------- 3. interface ---------------------------------------------------------------------------------------------*/





/* C Interface */

/*-------- 4. decorator ----------------------------------------------------------------------------------------------*/




/*-------- 5. factories ----------------------------------------------------------------------------------------------*/





#endif // ZYNQ_FAULT_TEST_TEST_TYPE_HPP
