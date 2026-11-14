/**
 *******************************************************************************
 * @file    ifar_policy.hpp
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

#ifndef ZYNQ_FAULT_TEST_IFAR_POLICY_HPP
#define ZYNQ_FAULT_TEST_IFAR_POLICY_HPP
/*-------- 1. includes and imports -----------------------------------------------------------------------------------*/


/* I. interface */

/* II. OS */

/* III. middlewares */

/* IV. drivers */
#include "test_types.hpp"

/* V. standard lib */
#include <cstdlib>

/*-------- 2. data type ----------------------------------------------------------------------------------------------*/




/*-------- 3. interface ---------------------------------------------------------------------------------------------*/

/**
 * @brief 注错地址遍历策略接口
 * @note  解耦地址来源：后续可派生 SingleFarPolicy, RangeFarPolicy, PblockEbdPolicy
 */
class IFarPolicy {
public:
    virtual ~IFarPolicy() = default;
    /**
     * @brief 是否还有待注入的目标地址
     */
    virtual bool hasNext() const = 0;
    /**
     * @brief 获取下一个注错地址并将内部迭代器步进
     */
    virtual FaultAddress nextAddress() = 0;
    /**
     * @brief 获取当前策略规划测试的比特总数
     */
    virtual size_t totalCount() const = 0;
    /**
     * @brief 复位迭代器至初始起始位置
     */
    virtual void reset() = 0;
};


/* C Interface */

/*-------- 4. decorator ----------------------------------------------------------------------------------------------*/




/*-------- 5. factories ----------------------------------------------------------------------------------------------*/





#endif // ZYNQ_FAULT_TEST_IFAR_POLICY_HPP
