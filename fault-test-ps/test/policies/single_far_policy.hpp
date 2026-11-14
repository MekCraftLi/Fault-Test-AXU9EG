/**
 *******************************************************************************
 * @file    single_far_policy.hpp
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

#ifndef ZYNQ_FAULT_TEST_SINGLE_FAR_POLICY_HPP
#define ZYNQ_FAULT_TEST_SINGLE_FAR_POLICY_HPP
/*-------- 1. includes and imports -----------------------------------------------------------------------------------*/


/* I. interface */
#include "test/ifar_policy.hpp"

/* II. OS */

/* III. middlewares */

/* IV. drivers */

/* V. standard lib */


/*-------- 2. data type ----------------------------------------------------------------------------------------------*/




/*-------- 3. interface ---------------------------------------------------------------------------------------------*/

/**
 * @brief 单点注错调试策略
 * @note  仅执行单次指定的 FAR 注入，用于系统点亮、时序验证与冒烟测试
 */
class SingleFarPolicy : public IFarPolicy {
  private:
    FaultAddress targetAddr_;
    bool executed_{false};

  public:
    /**
     * @brief 构造函数：指定唯一的注错物理坐标
     * @param far        物理配置帧地址
     * @param bitOffset  帧内比特偏移 (0 ~ 3231)
     * @param linearAddr 可选的线性地址索引
     */
    explicit SingleFarPolicy(uint32_t far, uint16_t bitOffset = 0, uint32_t linearAddr = 0)
        : targetAddr_(far, bitOffset, linearAddr), executed_(false) {}

    explicit SingleFarPolicy(const FaultAddress& addr) : targetAddr_(addr), executed_(false) {}

    bool hasNext() const override { return !executed_; }

    FaultAddress nextAddress() override {
        if (!executed_) {
            executed_ = true;
            return targetAddr_;
        }
        return targetAddr_;
    }

    size_t totalCount() const override { return 1; }

    void reset() override { executed_ = false; }
};


/* C Interface */

/*-------- 4. decorator ----------------------------------------------------------------------------------------------*/




/*-------- 5. factories ----------------------------------------------------------------------------------------------*/





#endif // ZYNQ_FAULT_TEST_SINGLE_FAR_POLICY_HPP
