# Retro 0001: 极简 FFI 底座、Android 交叉编译与 DHT 环境变量崩溃复盘

> **审查阶段**：项目初始化与 V1 最小 FFI 闭环（对应工单 `.scratch/minimal-rqbit-ffi/` 与 ADR-0001 ~ ADR-0003）  
> **复盘目标**：反思会话摩擦，改进 Agent 的开发与代码审查环境，而非指责业务代码本身。

---

## 一、会话摩擦点与踩坑事实回顾 (What Went Wrong)

1. **摩擦点 1：Android 交叉编译缺少 `rust-toolchain.toml`**
   - **现象**：在初次执行 `flutter build apk` 时，`native_toolchain_rust` 校验器抛出 `RustValidationException` 崩溃，阻断了整个 Android 构建流程。
   - **根本原因**：Flutter Native Assets 对 Rust 交叉编译有强约束，必须在 `rust/` 根目录下显式声明 `rust-toolchain.toml`，列出精确通道版本与所有目标平台的 target triples（`aarch64-linux-android` 等）。而初始搭建时该文件缺失。

2. **摩擦点 2：Android 运行时缺失 XDG 环境变量导致 DHT Panic 闪退**
   - **现象**：APK 成功打包并在真机运行时，调用启动服务直接闪退，底层报错 `Error -10: cannot determine project directory for com.rqbit.dht`。
   - **根本原因**：`librqbit` 官方默认的 `PersistentDht` 内部调用了 `get_configuration_directory("dht")`，该逻辑基于 Linux 桌面规范查找 `$HOME` 或 `XDG_*` 目录。移动端操作系统（Android / iOS）不存在此标准环境变量。由于 Agent 在桌面环境开发测试时 `$HOME` 天然存在，导致该隐患在编写初始代码时未能提前预判。

---

## 二、环境改进候选方案 (Environment Improvements)

按照 Matt Pocock 的规范分类法，推导环境防御措施：

### 1. 自动化校验 (Automated Checks)
- **发现**：代码库缺少在提交前验证跨平台工具链配置的校验脚本。
- **改进措施**：
  - 在 CI 或前置检查中增加对 `rust/rust-toolchain.toml` 的存在性与 targets 完整性校验；
  - 确保包含 `x86_64-pc-windows-msvc` 以及 Android 的 4 个标准架构（`aarch64`, `armv7`, `i686`, `x86_64`）。

### 2. 代码审查准则 (Reviewer Coding Standards)
- **发现**：实现 Agent 习惯性将桌面端的环境假设带入移动端跨平台库。
- **改进措施**（沉淀入 `CODING_STANDARDS.md`）：
  - **跨平台路径隔离准则**：任何引入的第三方 Rust crate 若涉及持久化（如 DHT、数据库、日志），严禁依赖 crate 内部基于环境变量的默认路径定位；必须强制由 Dart 宿主层通过 `path_provider` 显式注入沙盒绝对路径，或在 Rust 封装层显式兜底为相对路径。

### 3. 导航指针 (Navigation Pointers)
- **改进措施**：
  - 在 `AGENTS.md` 中增加指向 `docs/adr/0003-dht-persistence-path-isolation.md` 的导航提示，提醒未来编写 Rust 代码的 Agent 必须关注 Android 沙盒路径约束。
