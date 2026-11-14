/**
 *******************************************************************************
 * @file    idut_driver.hpp
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

#ifndef ZYNQ_FAULT_TEST_IDUT_DRIVER_HPP
#define ZYNQ_FAULT_TEST_IDUT_DRIVER_HPP
/*-------- 1. includes and imports -----------------------------------------------------------------------------------*/


/* I. interface */
#include "test_types.hpp"
/* II. OS */

/* III. middlewares */

/* IV. drivers */
#include "utils/byte_span.hpp"
#include "utils/time.hpp"

/* V. standard lib */
#include <stddef.h>
#include <stdint.h>

/*-------- 2. data type ----------------------------------------------------------------------------------------------*/




/*-------- 3. interface ---------------------------------------------------------------------------------------------*/

class IDutDriver {
  public:
    virtual ~IDutDriver()                                = default;

    virtual void reset()                                 = 0;

    virtual void sendInput(ByteSpan byteSpan) = 0;

    virtual void stepClock(uint32_t cycles = 1)          = 0;

    virtual bool isDone(utils::Timeout timeout)          = 0;

    virtual size_t getOutput(void* buff, size_t len)     = 0;
};

template <typename MetricsType> class IDutEvaluator {
  public:
    using Metrics                                                                    = MetricsType;

    virtual ~IDutEvaluator()                                                         = default;

    virtual EvaluationResult<MetricsType> evaluate(ByteSpan golden, ByteSpan actual) = 0;
};

/* C Interface */

/*-------- 4. decorator ----------------------------------------------------------------------------------------------*/




/*-------- 5. factories ----------------------------------------------------------------------------------------------*/





#endif // ZYNQ_FAULT_TEST_IDUT_DRIVER_HPP
