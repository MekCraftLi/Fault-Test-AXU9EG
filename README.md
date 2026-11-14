# Fault-Test-AXU9EG: ZYNQ UltraScale+ (XCZU9EG) 真实硬件故障注入与可靠性评估平台

本项目基于 **ALINX AXU9EG (AMD / Xilinx Zynq UltraScale+ XCZU9EG-FFVB1156-2-I)** 开发板，实现了面向硬件隔离模块（PBlock Isolated DUT）的 **100% 物理真实硅片故障注入与可靠性测试闭环**。

---

## 1. 系统架构与核心特性

- **目标平台**：ALINX AXU9EG (XCZU9EG-FFVB1156-2-I)
- **被测电路 (DUT)**：4-Tap Complex FIR Filter（包含全精度复数乘加数据通路）
- **物理隔离域 (PBlock)**：`pblock_TESTMODULE`
  - 物理区域：`CLOCK_REGION X1Y2` (`SLICE_X48Y140:SLICE_X53Y159`)
  - 覆盖资源：124 个 CLB / DSP Tiles，共计 348 个底层配置帧（Configuration Frames 17039–17406），总计 97,789 个 Essential Configuration Bits
- **注错引擎**：Xilinx UltraScale+ SEM Controller (IP v3.1)
  - 硬件通道：ICAPE3 物理配置原语
  - 总线仲裁：PS 固件在引导阶段向 `CSU_PCAP_CTRL` (0xFFCA3008) 写 0，释放 ICAPE3 物理总线给 PL SEM
  - 竞争控制：激励与比对期间保持 SEM 于 `Idle` 状态，消除后台硬件纠错（Scrubber）的竞争覆盖
- **真值模型 (Golden Model)**：$y = 127 \times x$，实时与 PS 纯计算模型逐样点硬件对比
- **自动化测试**：XSCT 脚本自动化下载 Bitstream、DDR4 目标字典及 ELF，并通过 UART (115200 8N1) 实时流式捕获，全程**零人工串口交互**

---

## 2. 仓库目录结构

```text
Fault-Test-AXU9EG/
├── README.md                           # 项目说明文档
├── .gitignore                          # 过滤 Vivado/CMake 中间生成物，保留最终交付物
├── real_hardware_uart_log.txt          # 真实硅片运行串口日志 (COM6 115200)
├── capture_and_run.py                  # 自动化测试编排脚本 (JTAG下载 + 串口采集)
├── generate_broad_pblock_targets.py    # 512 位广域 PBlock 敏感位字典生成器
├── fault-test-hw/                      # Vivado 硬件设计工程
│   ├── fault-test-hw.xpr              # Vivado 工程文件 (2022.2)
│   ├── src/                           # Verilog 源码 (top.v, bram_ctrl.v, filter.v, pblock.xdc 等)
│   ├── tcl/                           # 自动化构建与引脚约束脚本
│   └── fault-test-hw.srcs/            # Block Design (axi_bus.bd) 与 SEM IP 配置文件
└── fault-test-ps/                      # Cortex-A53 软件驱动与测试套件
    ├── CMakeLists.txt                 # PS 端 CMake 构建脚本
    ├── aarch64-none-elf-gcc.cmake     # 交叉编译工具链配置
    ├── application/                   # 主程序 (main.cpp, ebd_table.h)
    ├── drivers/                       # SEM IP 控制器 C++ 驱动
    ├── test/                          # DUT 驱动、Golden 模型比对及评估器
    └── bsp/                           # 最终交付成果物与板级支持包
        ├── top.bit                    # PL 最终比特流文件
        ├── top.xsa                    # 硬件描述包
        ├── application.elf            # Cortex-A53 最终可执行 ELF
        ├── ebd.bin                    # 512 位硬件注错字典二进制
        ├── frameRange.txt             # 帧地址列表
        ├── psu_init.tcl / psu_init.c  # PS 端初始化脚本与源码
        └── standalone_bsp/            # 裸机板级支持库
```

---

## 3. 实机测试与故障注入结果

### 3.1 真实硅片基准测试 (Baseline, 无注错)
在 8 组正交测试输入下，物理硬件输出与 Golden 模型 100% 匹配：
```text
[Phase 1] Executing Hardware Filter Baseline Verification...
  Input[0]=  10 -> Expected:   1270 | Hardware Out:   1270 [PASS]
  Input[1]=  20 -> Expected:   2540 | Hardware Out:   2540 [PASS]
  Input[2]= -15 -> Expected:  -1905 | Hardware Out:  -1905 [PASS]
  Input[3]=   8 -> Expected:   1016 | Hardware Out:   1016 [PASS]
  Input[4]=  35 -> Expected:   4445 | Hardware Out:   4445 [PASS]
  Input[5]= -42 -> Expected:  -5334 | Hardware Out:  -5334 [PASS]
  Input[6]=  60 -> Expected:   7620 | Hardware Out:   7620 [PASS]
  Input[7]= -18 -> Expected:  -2286 | Hardware Out:  -2286 [PASS]
[Phase 1] Hardware Filter Baseline Test: 100% [PASS]
```

### 3.2 典型物理失效捕获 (真实 CRAM 单比特翻转)
- **累加器高位失效 ($+8192 / +2^{13}$)**：
  `[ 58/512] Frame:17086 W:52 B:13 | LFA: 0x042BE68D | Diff: 8192 (HW: 9462 Exp: 1270) | [CRITICAL]`
- **数据通路算术位翻转 ($+256 / +2^8$)**：
  `[ 51/256] Frame:17106 W:44 B:20 | LFA: 0x042D2594 | Diff:  256 (HW:-5078 Exp:-5334) | [INTOLERABLE]`
- **乘法器部分积位翻转 ($+128 / +2^7$)**：
  `[169/256] Frame:17260 W:43 B:19 | LFA: 0x0436C573 | Diff:  128 (HW: 2668 Exp: 2540) | [INTOLERABLE]`

### 3.3 512 物理目标注错统计报告
```text
===============================================================
               FAULT INJECTION EXPERIMENT REPORT               
===============================================================
  DUT Architecture       : 4-Tap Complex FIR Filter            
  Isolation Domain       : pblock_TESTMODULE                   
  Total Injected Bits    : 512                                  
  Silent Faults          : 511 (99.8%)                      
  Tolerable Faults       : 0 (0.0%)                      
  Intolerable Faults     : 0 (0.0%)                      
  Critical Failures      : 1 (0.1%)                      
  Fault Vulnerability Rate: 0.19%                          
===============================================================
  [STATUS] EXPERIMENT FINISHED WITH ZERO USER PROMPT REQUIRED   
```
