---
status: closed
blocked_by: [01-rust-models-expansion]
---

# Ticket 03: 实现任务运维、Peer与元数据接口

## Goal
在 `RqbitClient` 中实现：
- `forgetTorrent(int id) -> Future<void>` (POST /torrents/{id}/forget)
- `addPeers(int id, List<String> peers) -> Future<int>` (POST /torrents/{id}/add_peers)
- `getPeerStats(int id, {String state}) -> Future<PeerStatsSnapshot>` (GET /torrents/{id}/peer_stats)
- `getTorrentMetadata(int id) -> Future<Uint8List>` (GET /torrents/{id}/metadata)
- `getTorrentHavesBytes(int id) -> Future<Uint8List>` (GET /torrents/{id}/haves，Accept: application/octet-stream)
- `getTorrentHavesSvg(int id) -> Future<String>` (GET /torrents/{id}/haves，SVG)

## Acceptance Criteria
- 在 `lib/client.dart` 实现方法。
- 在 `test/client_test.dart` 中针对上述接口添加测试并通过。
