# 0002. rqbitx 需求全景看板与 Dio / Rust 强类型契约规范

- **状态**: 规划中 (Draft / Ready for Dev)
- **日期**: 2026-10-15
- **关联文档**: [PRD-0001 种子流媒体播放交互规格书](0001-torrent-streaming-player-ux.md), [ADR-0001 极简 FFI 生命周期底座与 HTTP 隔离](../adr/0001-minimal-ffi-lifecycle-seam.md)

---

## 1. 需求全景矩阵看板 (打平版 · 无事件总线)

严格遵循单向数据流，废弃一切跨模块复杂广播的 EventBus。将业务操作与服务通信全面打平：

| 模块维度 | 具体需求项 | 需求说明与实现规范 | 对应 librqbit 源码 / API | 优先级 |
| :--- | :--- | :--- | :--- | :--- |
| **网络调用层** | **Dio HTTP 客户端封装** *(新增)* | 在 Dart 层使用 `dio` 作为官方 HTTP 客户端，统一处理 BaseUrl 绑定、超时重试、拦截器与底层异常收敛，取代裸 `dart:io` `HttpClient` | `dio: ^5.x` 封装，替代散落的 `HttpClient` | **P0 (核心基础)** |
| **类型契约层** | **Rust 源码 1:1 映射 Model 文件** *(新增)* | 声明强类型 Dart 数据模型，其字段名称与类型严格 1:1 映射自 `librqbit` Rust 源码结构体，拒绝弱类型 `Map` 漂移 | 映射自 `librqbit/src/api.rs`、`http_api_types.rs`、`torrent_state/stats.rs` | **P0 (核心基础)** |
| **流控与存储** | **按需切片下载流控 (防爆盘)** | 添加种子任务后立即调用 `update_only_files: []`（仅拉取元数据，不下载任何分片）；用户点击特定音视频播放时才更新为 `[file_idx]` | `POST /torrents/{id}/update_only_files`<br>(`http_api_types.rs::OnlyFiles`) | **P0 (必备功能)** |
| **监控与指标** | **实时下载/上传速率与进度条** | 定时拉取任务统计快照，计算瞬时下行/上行速率（如 `12.5 MB/s`）与下载进度比例 | `GET /torrents/{id}/stats/v1`<br>(`torrent_state/stats.rs::TorrentStats`) | **P0 (必备功能)** |
| **任务与解析** | **本地 `.torrent` 文件二进制上传** | 支持从本地相册/文件选择器读取 `.torrent` 二进制，以 `application/x-bittorrent` 形式上传并创建任务 | `POST /torrents?overwrite=true`<br>(`http_api/handlers/torrents.rs`) | **P1 (推荐)** |
| **任务控制** | **任务单项暂停与恢复** | 支持单独暂停或恢复指定种子任务的下载与做种，避免整体关闭服务 | `POST /torrents/{id}/pause`<br>`POST /torrents/{id}/start` | **P1 (推荐)** |
| **任务控制** | **仅卸载任务 (保留本地文件)** | 从引擎任务列表卸载种子，但保留磁盘已下载好的视频文件（区别于彻底物理清除的 `/delete`） | `POST /torrents/{id}/forget` | **P2 (可选)** |
| **网络与节点** | **公共 Tracker 池自动补全** | 启动或添加磁力时，自动补全精选的活跃公共 Tracker 节点列表，提升做种与 Peer 发现效率 | `RqbitStartConfig.trackers` 或磁力链接解析合并 | **P1 (推荐)** |
| **架构总线** | **全局响应式 EventBus 事件总线** | 跨组件事件分发流 | **【彻底废弃】**<br>坚持单向数据流与局部轻量轮询，绝不引入事件总线。 | 🚫 **明确排除** |

---

## 2. Rust 源码 1:1 映射模型映射表 (Source of Truth)

直接对照 `librqbit-9.0.1` 的 Rust 源码定义 Dart Model：

| Rust 结构体 (librqbit 源码位置) | 对应 Dart Model 类 | 核心字段对齐说明 |
| :--- | :--- | :--- |
| `TorrentDetailsResponse`<br>(`librqbit/src/api.rs:538`) | `TorrentDetails` | `id` (int?), `infoHash` (String), `name` (String?), `outputFolder` (String), `totalPieces` (int), `files` (List<TorrentFile>?), `stats` (TorrentStats?) |
| `TorrentDetailsResponseFile`<br>(`librqbit/src/api.rs:526`) | `TorrentFile` | `name` (String), `components` (List<String>), `length` (int), `included` (bool), `attributes` (FileDetailsAttrs) |
| `TorrentListResponse`<br>(`librqbit/src/api.rs:521`) | `TorrentListResponse` | `torrents` (List<TorrentDetails>) |
| `ApiAddTorrentResponse`<br>(`librqbit/src/api.rs:555`) | `AddTorrentResponse` | `id` (int?), `details` (TorrentDetails), `outputFolder` (String), `seenPeers` (List<String>?) |
| `TorrentStats`<br>(`librqbit/src/torrent_state/stats.rs:72`) | `TorrentStats` | `state` (TorrentStateEnum), `live` (TorrentLiveStats?), `totalBytes` (int), `progressBytes` (int), `finished` (bool) |
| `LiveStats`<br>(`librqbit/src/torrent_state/stats.rs:9`) | `TorrentLiveStats` | `snapshot` (StatsSnapshot), `averagePieceDownloadTime`, `timeRemaining` |
| `StatsSnapshot`<br>(`librqbit/src/torrent_state/live/stats/snapshot.rs:8`) | `StatsSnapshot` | `fetchedBytes` (int), `uploadedBytes` (int), `downloadSpeed` (Speed), `uploadSpeed` (Speed) |
| `Speed`<br>(`librqbit/src/torrent_state/stats.rs:224`) | `Speed` | `mbps` (double), `humanReadable` (String) |
| `TorrentAddQueryParams`<br>(`librqbit/src/http_api_types.rs:13`) | `AddTorrentOptions` | `overwrite` (bool?), `outputFolder` (String?), `subFolder` (String?), `onlyFiles` (List<int>?), `isUrl` (bool?), `listOnly` (bool?) |

---

## 3. Dio 客户端调用架构 (RqbitDioClient)

- **职责**：包装对 `http://127.0.0.1:<port>` 的所有 REST API 请求。
- **特性**：
  1. **响应强类型反序列化**：请求返回直接转换并返回 Rust 映射的 Dart Model。
  2. **拦截与错误收敛**：统一捕获 DioException 并映射为强类型业务异常。
  3. **单向调用**：调用者直接 `await client.getTorrentDetails(id)`，直观易懂，无事件总线绕路。
