/**
 *******************************************************************************
 * @file    zynqsem_hal.hpp
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
 * @date    2026/11/05
 * @version 1.0
 *******************************************************************************
 */
/* Define to prevent recursive inclusion -----------------------------------------------------------------------------*/

#ifndef ZYNQ_FAULT_TEST_ZYNQSEM_HAL_HPP
#define ZYNQ_FAULT_TEST_ZYNQSEM_HAL_HPP
/*-------- 1. includes and imports -----------------------------------------------------------------------------------*/


/* I. interface */
#include "isem_hal.h"

/* II. OS */

/* III. middlewares */

/* IV. drivers */
#include "xil_io.h"

/* V. standard lib */


/*-------- 2. enum ---------------------------------------------------------------------------------------------------*/




/*-------- 3. interface ---------------------------------------------------------------------------------------------*/

class ZynqSemHal : public ISemHal {
private:
    uintptr_t baseAddress_;
public:
    explicit ZynqSemHal(uintptr_t baseAddress): baseAddress_(baseAddress) {}

    void write32(uint32_t offset, uint32_t value) override {
        Xil_Out32((baseAddress_ + offset), value);
    }

    uint32_t read32(uint32_t offset) override {
        return Xil_In32((baseAddress_ + offset));
    }
};



/* C Interface */

/*-------- 4. decorator ----------------------------------------------------------------------------------------------*/




/*-------- 5. factories ----------------------------------------------------------------------------------------------*/





#endif // ZYNQ_FAULT_TEST_ZYNQSEM_HAL_HPP
