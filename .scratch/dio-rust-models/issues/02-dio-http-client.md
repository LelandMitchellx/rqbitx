---
id: 02
title: 引入 Dio 并封装高内聚 RqbitClient 客户端层
status: completed
blocked_by: [01]
---

## 目标
引入 `dio: ^5.7.0`，构建面向开发者的 `RqbitClient` 客户端，封装与本地 HTTP API 服务的网络交互。

## 核心职责
1. 管理 `baseUrl` (例如 `http://127.0.0.1:4242`) 与合理超时 (connectTimeout / receiveTimeout)。
2. 封装核心请求方法并返回强类型 Model：
   - `Future<TorrentListResponse> listTorrents()`
   - `Future<TorrentDetails> getTorrentDetails(int id)`
   - `Future<AddTorrentResponse> addTorrent(String source, {AddTorrentOptions? options})`
   - `Future<void> deleteTorrent(int id)`
   - `Future<void> pauseTorrent(int id)`
   - `Future<void> startTorrent(int id)`
3. 统一异常处理：将底层 `DioException` 转换为领域异常 `RqbitClientException`。

## 验收标准 (Acceptance Criteria)
1. `pubspec.yaml` 增加 `dio: ^5.7.0`。
2. 实现 `lib/src/client.dart`。
3. 编写 `test/client_test.dart`，使用 Mock/真机验证请求与异常拦截。
4. 绝不引入全局事件总线。
