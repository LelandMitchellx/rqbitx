# 03: Native Assets Toolchain

Status: open
Type: prototype
Blocked by: 01, 02

## Question
如何配置 Flutter 官方 Native Assets 体系（`hook/build.dart` 与 `native_toolchain_rust`），使插件支持开箱即用自动编译 Rust 动态库？

### 待决策点
- `pubspec.yaml` 的 `environment` 与 `native_toolchain_rust` 依赖版本锁定
- `hook/build.dart` 的 Rust 构建目标自动推导与产物分发
- 项目目录布局规范（如 `rust/` 与 `hook/` 的标准映射）
