# Map: Minimal rqbit HTTP Service FFI Plugin for Flutter

## Destination
在 Flutter 中通过极简 FFI 插件可靠拉起与优雅停止 rqbit HTTP 服务，返回实际监听的 HTTP URL，无任何冗余业务包装。

## Notes
- Effort slug: minimal-rqbit-ffi
- Tracker: Local markdown under `.scratch/minimal-rqbit-ffi/`
- 核心约束：V1 阶段**只做一件事**——拉起 rqbit HTTP 服务，提供基础启停生命周期控制，上层业务交互完全交由外部 HTTP 客户端。
- 设计原则：
  1. 单一高位接缝：FFI 边界只管理服务生命周期，不暴露任何种子、文件、配置包装类。
  2. 极致安全防熔断：Rust 端全流程 `catch_unwind` 拦截 Panic，禁止未捕获异常越过 C-ABI 造成 Flutter 崩溃。
  3. 纯净依赖：使用 Flutter Native Assets (`hook/build.dart`) + 纯 Rust WebPKI 根证书，零平台原生胶水代码。

## Decisions so far

<!-- the index: one line per closed ticket -->

## Not yet specified
- 移动端后台保活与前台通知服务机制（Android Foreground Service / iOS Background Mode）
- 弱网与端口占用冲突时的重试与降级策略
- 系统低内存（OOM）事件下的自动优雅落盘与资源释放

## Out of scope
- Dart 侧 Torrent 增删查改业务封装（全部交给标准 HTTP API）
- Dio 或第三方 HTTP 客户端的强绑定
- WebSocket / SSE 事件流监听机制
- Flutter Web 平台支持
