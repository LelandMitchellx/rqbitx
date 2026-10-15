# Complete librqbit HTTP API Spec

## Context & Motivation
librqbit 9.0.1 官方提供了完整的 HTTP REST API（见 `src/http_api/handlers/`），涵盖：
1. 会话与运行监控（根信息、全局统计、动态限速、动态日志等级）
2. DHT 统计与路由表（DHT 节点数、v4/v6 路由表快照）
3. 单任务深度控制与分析（元数据导出、Haves 比特位图、Peer 连接统计与加 Peer、仅移除任务不删文件）
4. 播放列表与高级能力（全局/单任务 M3U8 播放列表、磁力解析成 .torrent、本地文件夹做种生成）

当前 `RqbitClient` 仅实现了基础的 6 个接口（列表、详情、添加、删除、暂停/恢复、文件选择、单任务统计）。本 Spec 旨在全面对齐 librqbit 官方 HTTP API 规范，补齐所有剩余接口与 1:1 Rust 强类型 DTO。

## Interface Surface (All Endpoints Mapping)

| 类别 | HTTP 方法 & 路径 | Dart Client 方法名 | 返回类型 / 载荷 |
| :--- | :--- | :--- | :--- |
| **基础与会话** | `GET /` | `getServerInfo()` | `ServerInfo` |
| | `GET /stats` | `getSessionStats()` | `SessionStatsSnapshot` |
| | `GET /torrents/limits` | `getLimits()` | `LimitsConfig` |
| | `POST /torrents/limits` | `updateLimits(LimitsConfig limits)` | `void` |
| | `POST /rust_log` | `setRustLog(String rustLog)` | `void` |
| **DHT 统计** | `GET /dht/stats` | `getDhtStats()` | `DhtStats` |
| | `GET /dht/table` | `getDhtTable()` | `DhtRoutingTable` |
| **任务运维 & Peer** | `POST /torrents/{id}/forget` | `forgetTorrent(int id)` | `void` (保留文件) |
| | `POST /torrents/{id}/add_peers` | `addPeers(int id, List<String> peers)` | `int` (新增 peer 数) |
| | `GET /torrents/{id}/peer_stats` | `getPeerStats(int id, {String state})` | `PeerStatsSnapshot` |
| | `GET /torrents/{id}/metadata` | `getTorrentMetadata(int id)` | `Uint8List` (.torrent 字节) |
| | `GET /torrents/{id}/haves` | `getTorrentHavesBytes(int id)` / `getTorrentHavesSvg(int id)` | `Uint8List` / `String` |
| **播放列表 & 高级** | `GET /torrents/playlist` | `getGlobalPlaylist()` | `String` (M3U8) |
| | `GET /torrents/{id}/playlist` | `getTorrentPlaylist(int id)` | `String` (M3U8) |
| | `POST /torrents/resolve_magnet`| `resolveMagnet(String magnetUri)` | `Uint8List` |
| | `POST /torrents/create` | `createTorrent(String path, {...})` | `String` (magnet) / `Uint8List` |

## Seams & Testing Strategy
- **Seam**: `RqbitClient` 内部统一通过 Dio 实例发请求。
- **Contract Tests**: 使用 `MockDaemonAdapter` 模拟 axum 服务端返回结构，覆盖正常与异常分支。
- **End-to-End**: 在现有的 FFI 真实 daemon 集成测试上挂载验证。
