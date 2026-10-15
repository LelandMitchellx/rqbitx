# 0001. 最小 FFI 生命周期接缝与 HTTP 架构分层

- **状态**: 已接受 (accepted)
- **日期**: 2026-10-15

## 背景

在旧版参考实现（`code/rqbit`）中，Dart 表现层与 Rust 底层引擎高度耦合：
1. Dart 镜像了 Rust 内部复杂的种子数据模型，并暴露自定义响应式 Stream 事件流。
2. 维护着超过 1100 行的庞大单体 FFI 桥接文件，传递了数十个扁平入参。
3. 这种深度绑定的架构带来了巨大的维护成本、跨 FFI 内存泄漏隐患，以及升级底层 `librqbit` 时极高的破坏脆弱性。

## 决策

我们为 `rqbitx` 确立了**高内聚、单接缝（Single-Seam）的极简生命周期架构**：

1. **Rust FFI 职责边界收敛**：
   FFI 导出函数严格限制于进程与运行时生命周期的控制（`rqbit_start`, `rqbit_stop`, `rqbit_is_running`, `rqbit_last_error`）。
2. **业务交互全量下沉 HTTP REST API**：
   所有业务操作（添加种子/磁力链、状态查询、限速、音视频流媒体分片播放）全部通过 rqbit 原生内嵌的 localhost HTTP 接口进行通信，不再经由 FFI 传递复杂结构体。
3. **Rust Panic 安全隔离**：
   每个 C-ABI 原生导出函数必须由 `std::panic::catch_unwind` 包裹，彻底杜绝 Rust 运行时 panic 导致 Dart VM 崩溃闪退。
4. **现代化构建工具链**：
   全面遵循 Flutter Native Assets 标准（通过 `hook/build.dart` 与 `native_toolchain_rust` 驱动构建）。

## 结果与影响

- **收益（正面）**：
  - 原生 C-ABI 表面积极小（< 5 个符号），零复杂结构体编解码成本。
  - Dart 与 Rust 完全解耦，底层 `librqbit` 可独立平滑升级而无损上层业务。
  - 启动与停止状态确定性强，内存与资源完全可控。
- **代价（负面）**：
  - 高频实时指标的监控需要通过轮询或 SSE（Server-Sent Events）拉取，而非直接内存共享。
