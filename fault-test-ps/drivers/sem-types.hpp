/**
 *******************************************************************************
 * @file    sem-types.hpp
 * @brief   SEM 数据语义与强类型定义
 *******************************************************************************
 * @author  MekLi
 * @date    2026/11/05
 * @version 1.0
 *******************************************************************************
 */
/* Define to prevent recursive inclusion -----------------------------------------------------------------------------*/

#ifndef ZYNQ_FAULT_TEST_SEM_TYPES_HPP
#define ZYNQ_FAULT_TEST_SEM_TYPES_HPP
/*-------- 1. includes and imports -----------------------------------------------------------------------------------*/

/* I. interface */

/* II. OS */

/* III. middlewares */

/* IV. drivers */

/* V. standard lib */

#include <stdint.h>

/*-------- 2. enum ---------------------------------------------------------------------------------------------------*/

enum class SemState : uint8_t {
    Uninitialized = 0,
    Injection     = 1,
    Observation   = 2,
    Correction    = 4,
    Invalid       = 0xFF,
};

enum class InjectionResult : uint8_t {
    Success   = 0,
    Busy      = 1,
    Timeout   = 2,
    Triggered = 3,
};

enum class SemCmd : uint8_t {
    InjectErr = 0xC0, // Xilinx SEM 7-Series 标准错误注入命令 (允许后续检测与纠错)
};

/*-------- 3. interface ---------------------------------------------------------------------------------------------*/

inline SemState parseSemState(uint32_t rawVal) {
    uint8_t bits = rawVal & 0x07;
    switch (bits) {
        case 0:
            return SemState::Uninitialized;
        case 1:
            return SemState::Injection;
        case 2:
            return SemState::Observation;
        case 4:
            return SemState::Correction;
        default:
            return SemState::Invalid;
    }
}

inline const char* toString(SemState state) {
    switch (state) {
        case SemState::Uninitialized: return "Uninitialized";
        case SemState::Injection:     return "Injection";
        case SemState::Observation:   return "Observation";
        case SemState::Correction:    return "Correction";
        default:                      return "Invalid";
    }
}

/* C Interface */

/*-------- 4. decorator ----------------------------------------------------------------------------------------------*/

/*-------- 5. factories ----------------------------------------------------------------------------------------------*/

#endif // ZYNQ_FAULT_TEST_SEM_TYPES_HPP
