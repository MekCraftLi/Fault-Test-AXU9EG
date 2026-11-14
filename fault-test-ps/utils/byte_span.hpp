/**
 *******************************************************************************
 * @file    byte_span.hpp
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

#ifndef ZYNQ_FAULT_TEST_BYTE_SPAN_HPP
#define ZYNQ_FAULT_TEST_BYTE_SPAN_HPP
#include <cstdint>
/*-------- 1. includes and imports -----------------------------------------------------------------------------------*/


/* I. interface */

/* II. OS */

/* III. middlewares */

/* IV. drivers */

/* V. standard lib */
#include <cstdlib>


/*-------- 2. data type ----------------------------------------------------------------------------------------------*/




/*-------- 3. interface ---------------------------------------------------------------------------------------------*/

class ByteSpan {
private:
    const uint8_t* data_ {nullptr};
    size_t size_ {0};

public:
    constexpr ByteSpan() = default;
    constexpr ByteSpan(const void* data, size_t size): data_(static_cast<const uint8_t*>(data)), size_(size) {}

    template <typename T, size_t N>
    constexpr ByteSpan(const T (&arr)[N]) :data_(reinterpret_cast<const uint8_t*>(arr)), size_(N) {}

    constexpr const uint8_t* data() const { return data_; }
    constexpr size_t size() const { return size_; }
    constexpr bool empty() const { return size_ == 0; }

    constexpr uint8_t operator[](size_t index) const { return data_[index];}
};


/* C Interface */

/*-------- 4. decorator ----------------------------------------------------------------------------------------------*/




/*-------- 5. factories ----------------------------------------------------------------------------------------------*/





#endif // ZYNQ_FAULT_TEST_BYTE_SPAN_HPP
