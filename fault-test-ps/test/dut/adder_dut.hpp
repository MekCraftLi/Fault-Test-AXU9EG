/**
 *******************************************************************************
 * @file    adder_dut.hpp
 * @brief   加法器待测单元 (Adder DUT) 硬件驱动与领域评估器
 *          对齐加法器注错参考工程 (addr-shiyan) 的寄存器时序与评定模型
 *******************************************************************************
 * @author  MekLi
 * @date    2026/11/10
 * @version 1.0
 *******************************************************************************
 */
/* Define to prevent recursive inclusion -----------------------------------------------------------------------------*/

#ifndef ZYNQ_FAULT_TEST_ADDER_DUT_HPP
#define ZYNQ_FAULT_TEST_ADDER_DUT_HPP

/*-------- 1. includes and imports -----------------------------------------------------------------------------------*/

/* I. interface */
#include "test/idut_driver.hpp"

/* II. OS */

/* III. middlewares */

/* IV. drivers */
#include "xil_io.h"

/* V. standard lib */
#include <string.h>

/*-------- 2. data type ----------------------------------------------------------------------------------------------*/

namespace adder {

/**
 * @brief 加法器双操作数输入数据结构 (对齐 addr-shiyan: input_data_1, input_data_2)
 */
struct AdderInput {
    uint32_t a{1};
    uint32_t b{2};
};

/**
 * @brief 加法器算法专属度量类型
 */
struct AdderMetrics {
    uint32_t expectedSum{0};
    uint32_t actualSum{0};
    int32_t  diff{0};
};

/*-------- 3. interface ---------------------------------------------------------------------------------------------*/

/**
 * @brief 加法器 DUT 驱动实现类
 * @note  兼容 addr-shiyan 中的 BRAM 寄存器映射：
 *        - 输入 1 (i_data_1): REG_BASEADDR + 32*4 (0x80)
 *        - 输入 2 (i_data_2): REG_BASEADDR + 33*4 (0x84)
 *        - 输出 (o_data):    REG_BASEADDR + 34*4 (0x88)
 *        若未连接硬件或处于无硬件验证模式，自动以高确定性数学模型模拟加法器响应
 */
class AdderDutDriver : public IDutDriver {
private:
    uintptr_t baseAddr_{0};
    bool      isHardware_{false};
    uint32_t  opA_{0};
    uint32_t  opB_{0};
    uint32_t  result_{0};
    bool      done_{false};

    static constexpr uint32_t kOffsetInput1 = 32 * 4; // 0x80
    static constexpr uint32_t kOffsetInput2 = 33 * 4; // 0x84
    static constexpr uint32_t kOffsetOutput = 34 * 4; // 0x88

public:
    explicit AdderDutDriver(uintptr_t baseAddr = 0, bool isHardware = false)
        : baseAddr_(baseAddr), isHardware_(isHardware) {}

    void reset() override {
        opA_    = 0;
        opB_    = 0;
        result_ = 0;
        done_   = false;
        if (isHardware_ && baseAddr_ != 0) {
            Xil_Out32(baseAddr_ + kOffsetInput1, 0);
            Xil_Out32(baseAddr_ + kOffsetInput2, 0);
        }
    }

    void sendInput(ByteSpan byteSpan) override {
        if (!byteSpan.empty() && byteSpan.size() >= sizeof(AdderInput)) {
            const auto* input = reinterpret_cast<const AdderInput*>(byteSpan.data());
            opA_ = input->a;
            opB_ = input->b;

            if (isHardware_ && baseAddr_ != 0) {
                Xil_Out32(baseAddr_ + kOffsetInput1, opA_);
                Xil_Out32(baseAddr_ + kOffsetInput2, opB_);
            }
        }
    }

    void stepClock(uint32_t cycles = 1) override {
        (void)cycles;
        if (isHardware_ && baseAddr_ != 0) {
            result_ = Xil_In32(baseAddr_ + kOffsetOutput);
        } else {
            result_ = opA_ + opB_;
        }
        done_ = true;
    }

    bool isDone(utils::Timeout timeout) override {
        (void)timeout;
        return done_;
    }

    size_t getOutput(void* buff, size_t len) override {
        if (buff != nullptr && len >= sizeof(uint32_t)) {
            memcpy(buff, &result_, sizeof(uint32_t));
            return sizeof(uint32_t);
        }
        return 0;
    }
};

/**
 * @brief 加法器领域专属评估器 (AdderEvaluator)
 * @note  根据加法器输出差异进行精细化故障定性：
 *        - 完全一致 -> Silent (静默故障)
 *        - 最低有效位扰动 (|diff| == 1) -> Tolerable (可容忍)
 *        - 结果严重失真 -> Intolerable (不可容忍)
 *        - 长度异常/超时 -> SystemFailure (系统失效)
 */
class AdderEvaluator : public IDutEvaluator<AdderMetrics> {
public:
    EvaluationResult<AdderMetrics> evaluate(ByteSpan golden, ByteSpan actual) override {
        AdderMetrics metrics{};

        if (golden.size() < sizeof(uint32_t) || actual.size() < sizeof(uint32_t)) {
            return EvaluationResult<AdderMetrics>(FaultEffect::SystemFailure, metrics);
        }

        uint32_t goldenVal = 0;
        uint32_t actualVal = 0;
        memcpy(&goldenVal, golden.data(), sizeof(uint32_t));
        memcpy(&actualVal, actual.data(), sizeof(uint32_t));

        metrics.expectedSum = goldenVal;
        metrics.actualSum   = actualVal;
        metrics.diff        = static_cast<int32_t>(actualVal - goldenVal);

        if (actualVal == goldenVal) {
            return EvaluationResult<AdderMetrics>(FaultEffect::Silent, metrics);
        } else if (metrics.diff == 1 || metrics.diff == -1) {
            return EvaluationResult<AdderMetrics>(FaultEffect::Tolerable, metrics);
        } else {
            return EvaluationResult<AdderMetrics>(FaultEffect::Intolerable, metrics);
        }
    }
};

} // namespace adder

/* C Interface */

/*-------- 4. decorator ----------------------------------------------------------------------------------------------*/

/*-------- 5. factories ----------------------------------------------------------------------------------------------*/

#endif // ZYNQ_FAULT_TEST_ADDER_DUT_HPP
