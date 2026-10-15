# 0007. Dio HTTP 客户端架构与 librqbit 源码 1:1 强类型模型映射

- **状态**: 已接受 (Accepted)
- **日期**: 2026-10-15
- **决策者**: 架构团队 / 主公与虎鲸助手
- **关联规范**: [Spec: rqbitx Dio HTTP 客户端与 Rust 1:1 强类型数据模型](../../.scratch/dio-rust-models/spec.md)

---

## 1. 背景与痛点 (Context & Problem Statement)

在之前的实现中，Dart 端与底层 Rust 启动的 rqbit HTTP 守护进程通信存在以下问题：
1. **类型安全缺失**：使用弱类型的 `Map<String, dynamic>` 解析服务端响应，缺乏编译期类型检查，字段拼写错误容易在运行时隐蔽爆发。
2. **网络调用分散**：直接在各处裸写 `dart:io` 的 `HttpClient`，缺乏超时管理、BaseUrl 统一封装、统一异常收敛与请求拦截能力。
3. **分片下载爆盘风险**：添加磁力链接时默认拉取所有文件，移动端存储极易爆满，缺乏按需切片流控（`update_only_files: []`）的高层 API 封装。
4. **历史过度设计教训**：旧仓库引入了繁重的 EventBus 与 20+ 个过度嵌套的模型，导致状态流转混乱且难以维护。

---

## 2. 决策要点 (Decision Drivers)

- **严格 1:1 映射 Source of Truth**：直接依据本地编译依赖中的 `librqbit-9.0.1` Rust 源码定义 Dart 强类型 Model，严禁臆造字段。
- **高内聚的深模块客户端 (`RqbitClient`)**：基于官方标准 `dio: ^5.7.0` 封装统一网络客户端，统一处理连接超时、异常包装，屏蔽底层网络报文细节。
- **单向数据流与防爆盘流控**：原生提供 `updateOnlyFiles(id, fileIndices)` 与 `getTorrentStats(id)`，坚决废弃全局事件总线。

---

## 3. 具体实现架构 (Detailed Architecture)

### 3.1 强类型 DTO 结构与 Rust 源码对齐
在 `lib/models/` 下建立强类型类，所有类具备安全空容错的 `fromJson` 与 `toJson`：
- `TorrentDetails` 映射自 `librqbit/src/api.rs::TorrentDetailsResponse`
- `TorrentFile` 映射自 `librqbit/src/api.rs::TorrentDetailsResponseFile`
- `TorrentStats` 映射自 `librqbit/src/torrent_state/stats.rs::TorrentStats`
- `StatsSnapshot` 映射自 `librqbit/src/torrent_state/live/stats/snapshot.rs::StatsSnapshot`
- `Speed` 映射自 `librqbit/src/torrent_state/stats.rs::Speed`
- `AddTorrentOptions` 映射自 `librqbit/src/http_api_types.rs::TorrentAddQueryParams`

### 3.2 Dio 客户端封装 (`RqbitClient`)
- 位于 `lib/client.dart`，提供面向领域的异步方法：
  - `listTorrents() -> Future<TorrentListResponse>`
  - `getTorrentDetails(int id) -> Future<TorrentDetails>`
  - `addTorrent(String source, {AddTorrentOptions? options}) -> Future<AddTorrentResponse>`
  - `updateOnlyFiles(int id, List<int> fileIndices) -> Future<void>`
  - `getTorrentStats(int id) -> Future<TorrentStats>`
  - `pauseTorrent(int id)` / `startTorrent(int id)` / `deleteTorrent(int id)`
- 异常统一收敛为 `RqbitClientException`，捕获 HTTP 状态码与服务端错误信息。

---

## 4. 验证与后果 (Consequences & Verification)

### 正面成效 (Positive)
- **开发人体工程学**：IDE 具备完整的属性自动补全与类型推导（如 `details.files[0].length`）。
- **健壮性保障**：模型反序列化在 `test/models_test.dart` 中针对真实 JSON 全覆盖，并通过 `test/client_test.dart` 完成全链路契约测试。
- **质量指标**：全套 20 个测试全部通过（4s），`flutter analyze` 保持 0 问题。

### 明确排除 (Negative / Out of Scope)
- 严禁引入 EventBus 或任何跨模块全局响应式流，各业务组件按需单向请求并局部更新。
