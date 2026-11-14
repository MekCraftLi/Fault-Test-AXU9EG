cmake_minimum_required(VERSION 3.16)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

project(zynq_fault_test C CXX ASM)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(ARCH_FLAGS "-mcpu=cortex-a53")

set(CMAKE_C_FLAGS "${ARCH_FLAGS} -O0 -Wall")
set(CMAKE_CXX_FLAGS "${ARCH_FLAGS} -O0 -Wall -fno-exceptions -fno-rtti")

# 1. 全局目录定义
set(BSP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/bsp/standalone_bsp/psu_cortexa53_0")
set(LSCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/bsp/lscript.ld")
set(APPLICATION_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/application")

# 2. 头文件路径
include_directories(
        ${BSP_DIR}/include
        ${CMAKE_CURRENT_SOURCE_DIR}
)

# 3. 源文件路径
add_executable(application.elf
        ${APPLICATION_SRC_DIR}/main.cpp
)

# 4. 链接
target_link_options(application.elf PRIVATE
        ${ARCH_FLAGS}
        -Wl,-T -Wl,${LSCRIPT}
        -Wl,--gc-sections
)

target_link_directories(application.elf PRIVATE
        ${BSP_DIR}/lib
)

target_link_libraries(application.elf PRIVATE
        "-Wl,--start-group,-lxil,-lgcc,-lc,-lstdc++,--end-group"
)

add_custom_command(TARGET application.elf POST_BUILD
        COMMAND ${CMAKE_SIZE} application.elf
)
