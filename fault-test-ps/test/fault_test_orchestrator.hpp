/**
 *******************************************************************************
 * @file    fault_test_orchestrator.hpp
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

#ifndef ZYNQ_FAULT_TEST_FAULT_TEST_ORCHESTRATOR_HPP
#define ZYNQ_FAULT_TEST_FAULT_TEST_ORCHESTRATOR_HPP

/*-------- 1. includes and imports -----------------------------------------------------------------------------------*/


/* I. interface */
#include "test/idut_driver.hpp"
#include "test/ifar_policy.hpp"
#include "test/itest_reporter.hpp"
#include "test/test_types.hpp"
/* II. OS */

/* III. middlewares */

/* IV. drivers */
#include "drivers/sem-device.hpp"

/* V. standard lib */


/*-------- 2. data type ----------------------------------------------------------------------------------------------*/




/*-------- 3. interface ---------------------------------------------------------------------------------------------*/

template <typename MetricsType = EmptyMetrics> class FaultTestOrchestrator {
  public:
    FaultTestOrchestrator(SemDevice& sem, IDutDriver& dut, IFarPolicy& farPolicy, IDutEvaluator<MetricsType>& evaluator,
                          ITestReporter<MetricsType>& reporter, ByteSpan stimulus, uint32_t stepCycles = 1,
                          uint32_t dutTimeoutMs = 10, uint32_t semTimeoutMs = 50)
        : sem_(sem), dut_(dut), farPolicy_(farPolicy), evaluator_(evaluator), reporter_(reporter), stimulus_(stimulus),
          stepCycles_(stepCycles), dutTimeoutMs_(dutTimeoutMs), semTimeoutMs_(semTimeoutMs) {}

  private:
    SemDevice& sem_;
    IDutDriver& dut_;
    IFarPolicy& farPolicy_;
    IDutEvaluator<MetricsType>& evaluator_;
    ITestReporter<MetricsType>& reporter_;

    ByteSpan stimulus_;
    static constexpr size_t kMaxOutputSize_ = 1024;
    uint8_t goldenBuffer_[kMaxOutputSize_]{};
    size_t goldenSize_{0};
    uint8_t actualBuffer_[kMaxOutputSize_]{}; // 提升为类成员，常驻复用，栈零开销！
    size_t actualSize_{0};

    uint32_t stepCycles_{1};
    uint32_t dutTimeoutMs_{10};
    uint32_t semTimeoutMs_{50};

    TestSummary summary_;

    /**
     * @brief 等待 SEM 硬件进入就绪状态 (Observation 模式)
     * @param timeoutMs 超时时间 (毫秒)
     * @return true 就绪; false 超时
     */
    bool waitForSemReady(uint32_t timeoutMs) const {
        utils::Timeout deadline = utils::Timeout::fromMs(timeoutMs);
        while (!sem_.isReady()) {
            if (deadline.isExpired()) {
                return false;
            }
        }
        return true;
    }

    /**
     * @brief 翻转指定 FAR 帧的比特 (注错注入与翻转恢复通用事务)
     * @return true 翻转并等待就绪成功; false 超时或触发失败
     */
    bool flipFarBit(uint32_t far) const {
        if (!waitForSemReady(semTimeoutMs_)) {
            return false;
        }
        if (!sem_.trigger(far, SemCmd::InjectErr)) {
            return false;
        }
        utils::Time::delayUs(2);
        return waitForSemReady(semTimeoutMs_);
    }
    /**
     * @brief 统一完成单次迭代的耗时统计、汇总入库与报告上报
     */
    InjectionRecord<MetricsType> finishRecord(InjectionRecord<MetricsType>& record, const utils::Stopwatch& stopwatch, size_t currentIndex, size_t totalCount) {
        record.durationUs = static_cast<uint32_t>(stopwatch.elapsedUs());
        summary_.record(record.effect(), record.durationUs, record.recovered);
        reporter_.onIterationComplete(record, currentIndex, totalCount);
        return record;
    }



    bool captureBaseline() {
        dut_.reset();
        dut_.sendInput(stimulus_);
        dut_.stepClock(stepCycles_);

        if (!dut_.isDone(utils::Timeout::fromMs(dutTimeoutMs_))) {
            return false;
        }

        goldenSize_ = dut_.getOutput(goldenBuffer_, kMaxOutputSize_);
        return (goldenSize_ > 0);
    }

    InjectionRecord<MetricsType> executeSingleIteration(const FaultAddress& addr, size_t currentIndex, size_t totalCount) {
        InjectionRecord<MetricsType> record;
        record.address = addr;

        // 开始计时
        utils::Stopwatch stopwatch;

        // 开始向指定地址翻转比特
        if (!flipFarBit(addr.far)) {
            record.recovered         = false;
            record.evalResult.effect = FaultEffect::SystemFailure;
            return finishRecord(record, stopwatch, currentIndex, totalCount);
        }

        // 注错完成之后开始运行
        dut_.reset();
        dut_.sendInput(stimulus_);
        dut_.stepClock(stepCycles_);

        if (dut_.isDone(utils::Timeout::fromMs(dutTimeoutMs_))) {


            actualSize_ = dut_.getOutput(actualBuffer_, kMaxOutputSize_);
            record.evalResult =
                evaluator_.evaluate(ByteSpan(goldenBuffer_, goldenSize_), ByteSpan(actualBuffer_, actualSize_));
        } else {
            record.evalResult.effect = FaultEffect::SystemFailure;
        }

        // 3.翻转恢复配置
        record.recovered = flipFarBit(addr.far);

        return finishRecord(record, stopwatch, currentIndex, totalCount);
    }

  public:
    /**
     * @brief 执行完整的自动化注错测试流程
     * @return true 流程执行成功; false 基准捕获失败
     */
    bool run() {
        if (!captureBaseline()) {
            return false;
        }

        size_t totalCount = farPolicy_.totalCount();
        reporter_.onTestStart(totalCount);

        size_t currentIndex = 0;
        while (farPolicy_.hasNext()) {
            FaultAddress addr = farPolicy_.nextAddress();
            currentIndex++;
            executeSingleIteration(addr, currentIndex, totalCount);
        }

        reporter_.onTestFinish(summary_);
        return true;
    }

    const TestSummary& getSummary() const { return summary_; }
};


/* C Interface */

/*-------- 4. decorator ----------------------------------------------------------------------------------------------*/




/*-------- 5. factories ----------------------------------------------------------------------------------------------*/





#endif // ZYNQ_FAULT_TEST_FAULT_TEST_ORCHESTRATOR_HPP
