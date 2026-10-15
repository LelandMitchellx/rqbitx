# 0005. Flutter 热重启 (Hot Restart) 下 Rust 守护引擎的进程常驻与无缝重连 (Attach) 架构

- **状态**: 已接受 (accepted)
- **日期**: 2026-10-15
- **关联文档**: [ADR-0001 最小 FFI 生命周期隔离](0001-minimal-ffi-lifecycle-seam.md), [PRD-0001 种子流媒体播放交互规格书](../prd/0001-torrent-streaming-player-ux.md)

## 背景

在 Flutter 开发与调试循环中，热重启（Hot Restart, 快捷键 `R`）是极高频的操作。
在热重启过程中：
1. **宿主 OS 进程不退出**：Android 或 Windows 原生宿主进程及其内存空间保持存活，Rust 端通过静态变量（如 `static SERVICE: Mutex<Option<RqbitContext>>`）持有的 Tokio 异步运行时、Swarm 节点连接与 BitTorrent 会话仍在后台正常运行。
2. **Dart VM Isolate 内存被全量重置**：所有 Dart 层的类实例、静态引用、State 全被清空重建，且原有 Widget 树的 `dispose()` 会被依次触发。

此前存在两处痛点：
1. **State 误杀引擎**：`_BentoExampleAppState.dispose()` 中调用了 `_server?.stop()`，导致每次热重启 UI 时底层引擎都会被主动强制杀死。
2. **无法重连已存活引擎**：Rust FFI 未暴露当前运行端口获取接口（`rqbit_get_port`），且 `rqbit_start` 在发现服务已运行时仅简单返回错误码 `-6`。导致热重启后 Dart 调用自启动会抛出 `already running` 异常，使得 UI 假死显示为 `Error` 或 `OFFLINE`，已有下载任务与 Peer 连接全部脱管或中断。

## 决策

我们确立了**“底层引擎常驻进程，UI 热重启无缝重连 (Attach)”**的设计架构：

1. **Rust FFI 暴露运行状态与端口查询接口**：
   - 增加原生 C-ABI 导出：`rqbit_get_port() -> i32`。
   - 当 `SERVICE` 正在运行时返回已绑定的实际本地端口，未运行时返回 `0`。
2. **Dart 控制器增加当前实例探测与重连能力**：
   - 暴露 `RqbitServer.current({String host = '127.0.0.1'})`：当检测到 `_rqbitIsRunning() == 1` 且端口有效时，直接构造并返回当前运行中的 `RqbitServer` 实例。
   - 暴露 `RqbitServer.startOrAttach(...)`，以及在 `RqbitServer.start(..., {bool attachIfRunning = false})` 中支持在遇到服务已在运行时自动恢复接管，消除 `-6` 冲突崩溃。
3. **解耦 Widget 生命周期与 Native 守护进程**：
   - 从 UI 状态的 `dispose()` 中坚决移除 `_server?.stop()`。
   - 明确生命周期权责：热重启或页面销毁仅销毁 Flutter 前端视图与流定时器，底层的下载、DHT 路由与网络流媒体服务保持常驻；只有用户主动在 UI 界面点击“停止服务”按钮时，才显式触发 `_server.stop()`。
4. **热重启后的任务状态自动恢复**：
   - 在 UI 重新挂载重连成功后，主动向本地 `GET /torrents` 发起查询，若发现后台已有正在下载或解析的任务，自动还原任务卡片、文件列表与解析进度，做到无缝续接。

## 结果与影响

- **收益（正面）**：
  - **开发体验跃升**：在开发和调试 UI 样式时，随意按 `R` 热重启，正在下载的视频流与 Peer 节点连接丝毫不受影响，UI 毫秒级重新挂载并展示。
  - **健壮性增强**：杜绝了热重启竞争条件下 `rqbit_start` 撞锁报 `-6` 的崩溃与假死问题。
  - **状态机闭环**：实现了“真·后台下载引擎”的沉浸式体验。
- **代价（负面）**：
  - 开发者若修改了 Rust 底层逻辑或启动配置，不能仅靠 Flutter 热重启，需完整重启宿主进程（或先在 UI 点击“停止服务”后再重新启动）。
