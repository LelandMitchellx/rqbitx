# ADR 0009: RqbitServer 继承 RqbitClient 统一单实例设计

- **状态**: Accepted
- **日期**: 2026-10-15

## 1. 背景与问题 (Context)

在之前的架构设计中：
- `RqbitServer` 仅作为 FFI 守护进程生命周期的管理句柄（负责 `start`、`stop`、`current`、`port`、`url`）；
- `RqbitClient` 是基于 Dio 的强类型 HTTP API 客户端。

在实际使用与 UI 业务接入时（如 `example/lib/main.dart`），调用方必须同时维持两个对象引用：
```dart
RqbitServer? _server;
RqbitClient? _client;

_server = await RqbitServer.startOrAttach(...);
_client = RqbitClient(baseUrl: _server.url.toString());
```
这导致了一系列工程与心智负担：
1. **状态重复与冗余**：业务组件必须同步维护两个状态变量，并承受多次嵌套非空判断；
2. **生命周期割裂**：当 `_server.stop()` 停止本地服务时，`_client` 的连接池和请求未被联动释放；
3. **调用不够符合人体工程学**：既然在本地开发中，`RqbitServer` 启动后就是一个 HTTP 服务节点，开发者直觉上希望直接通过 `server.listTorrents()` 进行操作。

## 2. 决策方案 (Decision)

我们决定让 **`RqbitServer` 直接继承 `RqbitClient` (`class RqbitServer extends RqbitClient`)**：

1. **构造函数联动**：
   `RqbitServer` 内部构造函数直接透传 `baseUrl: url.toString()` 至 `super`：
   ```dart
   class RqbitServer extends RqbitClient {
     final int port;
     final Uri url;
     bool _isStopped = false;

     RqbitServer._({
       required this.port,
       required this.url,
       super.dio,
       super.connectTimeout,
       super.receiveTimeout,
     }) : super(baseUrl: url.toString());
   ```
2. **生命周期协同释放**：
   当 `server.stop()` 被调用时，不仅通过 C-ABI 通知 Rust 优雅退出，还同步触发 `dio.close(force: true)`，干净回收底层 TCP 连接与 HTTP 会话资源：
   ```dart
   Future<void> stop() async {
     if (_isStopped) return;
     _isStopped = true;
     dio.close(force: true);
     _rqbitStop();
   }
   ```
3. **保持里氏替换原则 (LSP)**：
   - `RqbitClient` 保持独立纯净，针对远程或跨机 rqbit 实例，用户依然可以自由使用 `RqbitClient(baseUrl: 'http://remote:3030')`；
   - 本地的 `RqbitServer` 属于 `RqbitClient` 的特化实现，在需要接收 `RqbitClient` 的任何服务或抽象中均可无缝传入。

## 3. 架构影响与收益 (Consequences)

- **开发体验极其轻量**：启动后只需一个对象句柄：
  ```dart
  final server = await RqbitServer.startOrAttach(downloadDir: path);
  final list = await server.listTorrents();
  final info = await server.getServerInfo();
  await server.stop();
  ```
- **消除了 UI 层的状态冗余**：`example/lib/main.dart` 彻底删除了独立的 `_client` 变量，简化了 9 处调用链路。
- **完全向后兼容**：不破坏任何 `RqbitClient` 的既有独立使用方式。
