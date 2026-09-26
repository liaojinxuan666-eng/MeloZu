# MeloZu 🚀

> A Next-Generation Nintendo Switch Emulator for iOS based on Pomelo/Sudachi architecture.

[![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS-lightgrey.svg)]()
[![Backend](https://img.shields.io/badge/Graphics-MoltenVK%2FAlloyCore-orange.svg)]()

**MeloZu** 是一个专注于 iOS 平台的 Nintendo Switch 模拟器项目，基于 Pomelo / Sudachi 架构深度重构。项目旨在突破现有 iOS 模拟器的性能瓶颈与交互局限，打造原生级流畅度与极致还原体验。

---

### ✨ 核心特性 (Key Features)

* **原生 Switch UI 架构**：抛弃传统割裂的前端界面，通过原生固件直接引导进入 Switch 系统 UI (`qlaunch`)，提供真正的掌机系统沉浸感。
* **ARM64 NCE 指令集直译**：基于 ARM64-to-ARM64 NCE (Native Code Execution) 技术，大幅降低 CPU 仿真开销与发热量。
* **混合图形渲染后端**：
  * **MoltenVK**：保证基础 Vulkan 指令到 Metal 的高效兼容转换。
  * **AlloyCore (研发中)**：自研 Metal 原生图形渲染引擎，重构渲染管线与着色器处理，追求极致帧率。

---

### 🗺️ 技术 Roadmap

- [x] 基于 Pomelo / Sudachi 建立 iOS 核心代码分支
- [ ] **UI 架构重构**：实现加载固件后直接 boot 到原生 Switch 主界面
- [ ] **NCE CPU 拓展**：优化 iOS 环境下的内存映射与系统调用响应
- [ ] **AlloyCore 渲染引擎**：开发自研 Metal 图形后端与统一着色器编译层
- [ ] **输入与手感适配**：对 iOS 触控手柄、MFi 及 PS/Xbox 手柄的低延迟映射

---

### 🔗 声明与致谢 (Credits & Disclaimer)

* 基于 [Sudachi](https://github.com/sudachi-emu) / [Pomelo](https://github.com/pomelo-emu) 等开源模拟器项目的卓越贡献。
* 本项目仅供技术研究与学习交流使用。
