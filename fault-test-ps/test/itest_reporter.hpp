/**
 *******************************************************************************
 * @file    itest_reporter.hpp
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
 * @date    2026/11/10
 * @version 1.0
 *******************************************************************************
 */
/* Define to prevent recursive inclusion -----------------------------------------------------------------------------*/

#ifndef ZYNQ_FAULT_TEST_ITEST_REPORTER_HPP
#define ZYNQ_FAULT_TEST_ITEST_REPORTER_HPP
/*-------- 1. includes and imports -----------------------------------------------------------------------------------*/


/* I. interface */
#include "test_types.hpp"

/* II. OS */

/* III. middlewares */

/* IV. drivers */

/* V. standard lib */
#include <cstdlib>

/*-------- 2. data type ----------------------------------------------------------------------------------------------*/




/*-------- 3. interface ---------------------------------------------------------------------------------------------*/

template <typename MetricsType>
class ITestReporter {
public:
    virtual ~ITestReporter() = default;
    /**
     * @brief 测试任务开始通知
     * @param total_count 本次规划测试的注错比特总数
     */
    virtual void onTestStart(size_t total_count) = 0;
    /**
     * @brief 单点注错闭环完成通知 (每完成一个比特触发一次)
     * @param record        本次注错的完整实验记录切片 (含物理坐标、评定等级、专属度量、微秒耗时)
     * @param current_index 当前完成的测试点序号 (从 1 开始累加)
     * @param total_count   本次测试规划的总点数
     */
    virtual void onIterationComplete(
        const InjectionRecord<MetricsType>& record,
        size_t current_index,
        size_t total_count
    ) = 0;
    /**
     * @brief 测试任务全部结束通知
     * @param summary 全局宏观统计报表 (致命失效率、任务弹性率、平均单点耗时)
     */
    virtual void onTestFinish(const TestSummary& summary) = 0;
};


/* C Interface */

/*-------- 4. decorator ----------------------------------------------------------------------------------------------*/




/*-------- 5. factories ----------------------------------------------------------------------------------------------*/





#endif // ZYNQ_FAULT_TEST_ITEST_REPORTER_HPP
