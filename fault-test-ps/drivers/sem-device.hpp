/**
 *******************************************************************************
 * @file    sem-device.hpp
 * @brief   SEM 硬件外设专用控制器驱动 (纯驱动层，零时间耦合)
 *******************************************************************************
 * @author  MekLi
 * @date    2026/11/05
 * @version 1.0
 *******************************************************************************
 */
/* Define to prevent recursive inclusion -----------------------------------------------------------------------------*/

#ifndef ZYNQ_FAULT_TEST_SEM_DEVICE_HPP
#define ZYNQ_FAULT_TEST_SEM_DEVICE_HPP
/*-------- 1. includes and imports -----------------------------------------------------------------------------------*/

/* I. interface */
#include "sem-types.hpp"
#include "hal/isem_hal.h"

/* II. OS */

/* III. middlewares */

/* IV. drivers */

/* V. standard lib */
#include <stdint.h>

/*-------- 2. enum ---------------------------------------------------------------------------------------------------*/

/*-------- 3. interface ---------------------------------------------------------------------------------------------*/

class SemDevice {
private:
    ISemHal& hal_;
    static constexpr uint32_t kOffsetFar    = 0x00;
    static constexpr uint32_t kOffsetCmd    = 0x04;
    static constexpr uint32_t kOffsetStrobe = 0x08;
    static constexpr uint32_t kOffsetStatus = 0x0C;

public:
    explicit SemDevice(ISemHal& hal) : hal_(hal) {}

    // 硬件控制器对象天然不可复制（禁用拷贝构造和拷贝赋值）
    SemDevice(const SemDevice&) = delete;
    SemDevice& operator=(const SemDevice&) = delete;

    /**
     * @brief 获取当前 SEM 硬件状态强类型
     */
    SemState getSemState() const {
        uint32_t raw = hal_.read32(kOffsetStatus);
        return parseSemState(raw);
    }

    /**
     * @brief 检查当前硬件是否处于 Observation 观察状态 (可注错就绪状态)
     */
    bool isReady() const {
        return getSemState() == SemState::Observation;
    }

    /**
     * @brief 纯硬件原子注错触发动作 (耗时纳秒级，非阻塞立即返回)
     * @param farAddress 目标配置帧线性地址
     * @param cmd        注错命令字 (如 SemCmd::InjectErr)
     * @return true 触发成功; false 硬件正忙或未处于就绪状态
     */
    bool trigger(uint32_t farAddress, SemCmd cmd) {
        if (!isReady()) {
            return false;
        }
        hal_.write32(kOffsetFar, farAddress);
        hal_.write32(kOffsetCmd, static_cast<uint32_t>(cmd));
        hal_.write32(kOffsetStrobe, 1);
        hal_.write32(kOffsetStrobe, 0);
        return true;
    }
};

/* C Interface */

/*-------- 4. decorator ----------------------------------------------------------------------------------------------*/

/*-------- 5. factories ----------------------------------------------------------------------------------------------*/

#endif // ZYNQ_FAULT_TEST_SEM_DEVICE_HPP
