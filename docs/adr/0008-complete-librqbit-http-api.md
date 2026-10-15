# 0008: 完整对齐 librqbit 官方 HTTP API 与领域模型规范

- 状态: accepted
- 日期: 2026-10-15

## 背景与上下文
在先前的版本中，`RqbitClient` 仅实现了基础的 6 个接口（任务列表、详情、添加、删除、暂停/启动、文件选择更新与单任务统计）。然而官方 `librqbit` 9.0.1 暴露了非常丰富的 HTTP REST 运维与监控能力，包括全局会话统计、DHT 网络状态、单任务 Peer 分析与元数据导出、M3U8 播放列表生成以及做种生成。

为了满足高阶离线下载与媒体流媒体播放场景，需在保持轻量（基于 Dio 无冗余重型依赖）的前提下，1:1 全量映射 librqbit 官方 HTTP 接口与 Rust 结构体。

## 架构决策

### 1. 结构体 1:1 映射 (Rust DTO -> Dart Model)
所有模型均在 `lib/models/` 下独立成模块，具备严格类型安全与安全空容错的 `fromJson` 与 `toJson`：
- `ServerInfo`：服务端名称、版本号与全量 API 路由映射表。
- `LimitsConfig`：会话级上传与下载限速带宽配置。
- `SessionStatsSnapshot`：会话统计快照，包含网络吞吐计数器 (`SessionCounters`)、聚合 Peer 状态 (`AggregatePeerStats`)、各协议连接快照 (`ConnectStatsSnapshot`)。
- `DhtStats` & `DhtRoutingTableResponse`：DHT 20 字节节点 ID、请求计数及 v4/v6 路由表。
- `PeerStatsSnapshot`：各 Peer 连接状态、网络握手耗时、数据传输计数器与客户端标识 (`client_name`)。

### 2. 接口分层与客户端方法全集
在 `RqbitClient` (`lib/client.dart`) 中提供以下分类方法：
1. **服务与会话监控**：
   - `getServerInfo() -> Future<ServerInfo>` (`GET /`)
   - `getSessionStats() -> Future<SessionStatsSnapshot>` (`GET /stats`)
   - `getLimits() -> Future<LimitsConfig>` (`GET /torrents/limits`)
   - `updateLimits(LimitsConfig limits) -> Future<void>` (`POST /torrents/limits`)
   - `setRustLog(String rustLog) -> Future<void>` (`POST /rust_log`)
2. **DHT 分布式哈希表**：
   - `getDhtStats() -> Future<DhtStats>` (`GET /dht/stats`)
   - `getDhtTable() -> Future<DhtRoutingTableResponse>` (`GET /dht/table`)
3. **任务运维与 Peer 拓扑**：
   - `forgetTorrent(int id) -> Future<void>` (`POST /torrents/{id}/forget`，保留已下载文件)
   - `addPeers(int id, List<String> peers) -> Future<int>` (`POST /torrents/{id}/add_peers`)
   - `getPeerStats(int id, {String state}) -> Future<PeerStatsSnapshot>` (`GET /torrents/{id}/peer_stats`)
   - `getTorrentMetadata(int id) -> Future<Uint8List>` (`GET /torrents/{id}/metadata`)
   - `getTorrentHavesBytes(int id) -> Future<Uint8List>` (`GET /torrents/{id}/haves`, 二进制 bitfield)
   - `getTorrentHavesSvg(int id) -> Future<String>` (`GET /torrents/{id}/haves`, SVG 格式)
4. **播放列表与做种高级能力**：
   - `getGlobalPlaylist() / getGlobalPlaylistUrl()` (`GET /torrents/playlist`, M3U8)
   - `getTorrentPlaylist(int id) / getTorrentPlaylistUrl(int id)` (`GET /torrents/{id}/playlist`, M3U8)
   - `resolveMagnet(String magnetUri) -> Future<Uint8List>` (`POST /torrents/resolve_magnet`)
   - `createTorrent(String folderPath, {...}) -> Future<dynamic>` (`POST /torrents/create`)

### 3. 测试与验证策略
- 所有 DTO 具备序列化/反序列化单元测试覆盖 (`test/models_test.dart`)。
- 所有接口具备通过 `MockDaemonAdapter` 模拟的 Contract 测试覆盖 (`test/client_test.dart`)。
- 与真实 FFI 后台守护进程联动测试 (`test/rqbitx_test.dart`)。

## 效果与影响
- 提供开箱即用、无缝对齐 librqbit 全部后端能力的 Dart SDK。
- 全量 33 个单元与集成测试均 100% 通过，两级工程 (`rqbitx` 与 `example`) 代码分析均为 0 警告。
