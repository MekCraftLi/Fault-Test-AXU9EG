/**
 *******************************************************************************
 * @file    mock_evaluator.hpp
 * @brief   模拟算法评估器实现类 (用于端到端冒烟测试)
 *******************************************************************************
 * @author  MekLi
 * @date    2026/11/10
 * @version 1.0
 *******************************************************************************
 */
/* Define to prevent recursive inclusion -----------------------------------------------------------------------------*/

#ifndef ZYNQ_FAULT_TEST_MOCK_EVALUATOR_HPP
#define ZYNQ_FAULT_TEST_MOCK_EVALUATOR_HPP

/*-------- 1. includes and imports -----------------------------------------------------------------------------------*/

/* I. interface */
#include "test/idut_driver.hpp"

/* II. OS */

/* III. middlewares */

/* IV. drivers */

/* V. standard lib */
#include <string.h>

/*-------- 2. enum ---------------------------------------------------------------------------------------------------*/

/*-------- 3. class --------------------------------------------------------------------------------------------------*/

/**
 * @brief 模拟加法器输出评估器
 */
class MockEvaluator : public IDutEvaluator<EmptyMetrics> {
public:
    EvaluationResult<EmptyMetrics> evaluate(ByteSpan golden, ByteSpan actual) override {
        // 1. 长度异常或空数据：不可容忍失效
        if (golden.size() == 0 || actual.size() == 0 || golden.size() != actual.size()) {
            return EvaluationResult<EmptyMetrics>(FaultEffect::Intolerable, EmptyMetrics{});
        }

        // 2. 逐字节比对
        size_t diff_bytes = 0;
        for (size_t i = 0; i < golden.size(); i++) {
            if (golden[i] != actual[i]) {
                diff_bytes++;
            }
        }

        // 3. 按照差异比例定性
        if (diff_bytes == 0) {
            return EvaluationResult<EmptyMetrics>(FaultEffect::Silent, EmptyMetrics{});
        } else if (diff_bytes <= 1) {
            // 差异极其微弱，定为任务可容忍
            return EvaluationResult<EmptyMetrics>(FaultEffect::Tolerable, EmptyMetrics{});
        } else {
            // 差异较大，不可容忍
            return EvaluationResult<EmptyMetrics>(FaultEffect::Intolerable, EmptyMetrics{});
        }
    }
};

#endif // ZYNQ_FAULT_TEST_MOCK_EVALUATOR_HPP
