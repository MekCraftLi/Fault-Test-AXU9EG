/**
 *******************************************************************************
 * @file    mock_dut.hpp
 * @brief   纯内存模拟待测算法驱动 (用于在无真实 PL 硬件算法时验证注错系统闭环)
 *******************************************************************************
 * @author  MekLi
 * @date    2026/11/10
 * @version 1.0
 *******************************************************************************
 */
/* Define to prevent recursive inclusion -----------------------------------------------------------------------------*/

#ifndef ZYNQ_FAULT_TEST_MOCK_DUT_HPP
#define ZYNQ_FAULT_TEST_MOCK_DUT_HPP

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
 * @brief 模拟待测算子 (内部实现一个 32 位加法器: Result = A + B)
 */
class MockDutDriver : public IDutDriver {
private:
    uint32_t op_a_{0};
    uint32_t op_b_{0};
    uint32_t result_{0};
    bool     done_{false};
    uint32_t fault_mask_{0}; // 模拟故障扰动掩码

public:
    struct InputData {
        uint32_t a;
        uint32_t b;
    };

    MockDutDriver() = default;

    void reset() override {
        op_a_   = 0;
        op_b_   = 0;
        result_ = 0;
        done_   = false;
    }

    void sendInput(ByteSpan byteSpan) override {
        if (!byteSpan.empty() && byteSpan.size() >= sizeof(InputData)) {
            const auto* input = reinterpret_cast<const InputData*>(byteSpan.data());
            op_a_ = input->a;
            op_b_ = input->b;
        }
    }

    void stepClock(uint32_t cycles = 1) override {
        (void)cycles;
        // 模拟加法运算，加上可能注入的位扰动
        result_ = (op_a_ + op_b_) ^ fault_mask_;
        done_   = true;
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

    /**
     * @brief 辅助测试接口：人为注入模拟扰动掩码 (用于单元测试评估器响应)
     */
    void setFaultMask(uint32_t mask) {
        fault_mask_ = mask;
    }
};

#endif // ZYNQ_FAULT_TEST_MOCK_DUT_HPP
