/**
 *******************************************************************************
 * @file    range_for_policy.hpp
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

#ifndef ZYNQ_FAULT_TEST_RANGE_FOR_POLICY_HPP
#define ZYNQ_FAULT_TEST_RANGE_FOR_POLICY_HPP
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
 * @brief 连续物理帧范围注错扫描策略
 * @note  在给定的 [startFar, endFar] 范围内逐帧迭代，支持指定固定的帧内位偏移
 */
class RangeFarPolicy : public IFarPolicy {
  private:
    uint32_t startFar_;
    uint32_t endFar_;
    uint32_t currentFar_;
    uint16_t bitOffset_;

  public:
    /**
     * @brief 构造函数：指定起始帧与结束帧 (闭区间)
     * @param startFar   起始物理配置帧地址
     * @param endFar     结束物理配置帧地址
     * @param bitOffset  帧内比特偏移 (0 ~ 3231, 默认为 0)
     */
    RangeFarPolicy(uint32_t startFar, uint32_t endFar, uint16_t bitOffset = 0)
        : startFar_(startFar), endFar_(endFar), currentFar_(startFar), bitOffset_(bitOffset) {}

    bool hasNext() const override { return currentFar_ <= endFar_; }

    FaultAddress nextAddress() override {
        if (!hasNext()) {
            return FaultAddress(endFar_, bitOffset_, static_cast<uint32_t>(totalCount()));
        }
        uint32_t linear = currentFar_ - startFar_;
        FaultAddress addr(currentFar_, bitOffset_, linear);
        currentFar_++;
        return addr;
    }

    size_t totalCount() const override {
        return (endFar_ >= startFar_) ? static_cast<size_t>(endFar_ - startFar_ + 1) : 0;
    }

    void reset() override { currentFar_ = startFar_; }
};


/* C Interface */

/*-------- 4. decorator ----------------------------------------------------------------------------------------------*/




/*-------- 5. factories ----------------------------------------------------------------------------------------------*/





#endif // ZYNQ_FAULT_TEST_RANGE_FOR_POLICY_HPP
