# Spec: rqbitx Dio HTTP 客户端与 Rust 1:1 强类型数据模型

## 1. Problem Statement (痛点与背景)
当前 `rqbitx` 具备了高可用的极简 FFI 生命周期（启动、停止、热重载常驻、端口探测），但与底层 rqbit 守护进程的 HTTP API 通信存在如下痛点：
1. **弱类型与契约漂移**：前端直接使用 `Map<String, dynamic>` 解析 JSON 响应。字段拼写错误、类型转换失败只能在运行时暴露，缺乏类型推导与自动补全。
2. **缺乏统一网络客户端**：直接依赖裸 `dart:io` 的 `HttpClient` 散落在各处，缺乏 BaseUrl 统一管理、超时控制、统一异常收敛与请求拦截能力。
3. **分片全量下载风险 (爆盘隐患)**：添加磁力链接时默认下载所有文件。缺乏按需切片下载流控（`update_only_files: []`），极易导致移动端存储迅速被无用文件占满。

## 2. Solution (解决方案)
遵循 Matt Pocock 工程原则，在保证极简与深模块（Deep Module）的前提下：
1. **Rust 源码 1:1 强类型映射**：
   - 严格依据 `librqbit-9.0.1` 的 Rust 源码（`src/api.rs`、`src/http_api_types.rs`、`src/torrent_state/stats.rs`）声明 Dart 强类型 Model。
   - 所有 Model 提供强类型 `fromJson` 和 `toJson`，全面杜绝手写 key 漂移。
2. **Dio 封装高内聚客户端 (`RqbitClient`)**：
   - 依赖 `dio: ^5.7.0`，接管对 `http://127.0.0.1:<port>` 的所有请求。
   - 统一异常处理（将 `DioException` 转换为领域异常 `RqbitClientException`）。
   - 提供直接返回强类型 Model 的方法（`listTorrents`、`getTorrentDetails`、`addTorrent`、`deleteTorrent`、`updateOnlyFiles` 等）。
3. **单向数据流与防爆盘流控**：
   - 添加任务时默认传参或即时触发 `update_only_files: []`，保证仅拉取元数据。
   - 用户发起播放时才更新为 `[file_idx]`。

## 3. User Stories (用户故事)
- **US1: 作为开发者**，我希望通过 `final details = await client.getTorrentDetails(id)` 直接获得强类型的 `TorrentDetails` 对象，并能代码补全 `details.files[0].name` 与 `details.totalPieces`，以便安全编写业务代码。
- **US2: 作为开发者**，我希望在任务创建后能够通过 `await client.updateOnlyFiles(id, [0])` 精确指定只下载第 0 个视频切片，以防止下载不需要的无用文件或爆盘。
- **US3: 作为流媒体播放器使用者**，我希望在播放时能实时查看瞬时下载速度与已下载字节数，因此客户端需能通过 `await client.getTorrentStats(id)` 获取最新的速率指标。

## 4. Seams (测试接缝与架构边界)
遵循 Matt Pocock "单一高层抗重构接缝" 原则：
- **模型序列化接缝 (`models_test.dart`)**：
  - 测试用例直接输入真实 `librqbit` HTTP API 返回的 JSON 报文样本，验证反序列化后的各字段类型、嵌套列表、枚举与边界 null 值。
- **客户端网络接缝 (`client_test.dart`)**：
  - 接缝置于 `RqbitClient` 与真实/Mock HTTP 服务之间。
  - 使用 Dio 的 `HttpClientAdapter` 进行无副作用契约测试，并结合真机运行的 `RqbitServer` 执行端到端集成测试。
- **单向生命周期隔离**：
  - `RqbitServer` (FFI) 仅负责生命周期与端口提供。
  - `RqbitClient` (Dio) 接收 `baseUrl` 进行所有业务交互，两模块低磨损解耦。

## 5. Out of Scope (明确排除项)
1. **严禁引入全局 EventBus / 事件总线**：禁止跨模块广播事件机制，坚决使用单向请求与局部轮询。
2. **不引入多余的第三方大库**：除官方标准 `dio` 外，不引入其他繁重网络或状态管理框架。
3. **不在此阶段重写 example 的 UI 布局**：保持现有 Bento 布局不变，只完成 SDK 核心层与契约测试。

## 6. Rust 1:1 映射清单 (Source of Truth)
- `TorrentDetailsResponse` (`librqbit/src/api.rs:538`) -> `TorrentDetails`
- `TorrentDetailsResponseFile` (`librqbit/src/api.rs:526`) -> `TorrentFile`
- `TorrentListResponse` (`librqbit/src/api.rs:521`) -> `TorrentListResponse`
- `ApiAddTorrentResponse` (`librqbit/src/api.rs:555`) -> `AddTorrentResponse`
- `TorrentStats` (`librqbit/src/torrent_state/stats.rs:72`) -> `TorrentStats`
- `LiveStats` (`librqbit/src/torrent_state/stats.rs:9`) -> `TorrentLiveStats`
- `StatsSnapshot` (`librqbit/src/torrent_state/live/stats/snapshot.rs:8`) -> `StatsSnapshot`
- `Speed` (`librqbit/src/torrent_state/stats.rs:224`) -> `Speed`
- `TorrentAddQueryParams` (`librqbit/src/http_api_types.rs:13`) -> `AddTorrentOptions`

## 7. Verification Plan (验收契约)
- `flutter test` 单元测试覆盖全部 9 个核心 Model 的 JSON 编解码。
- `flutter test` 契约测试覆盖 `RqbitClient` 的核心 HTTP API 调用。
- `flutter analyze` 保持 0 errors, 0 warnings。
