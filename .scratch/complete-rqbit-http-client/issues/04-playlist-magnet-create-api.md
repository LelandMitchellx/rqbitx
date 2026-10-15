---
status: closed
blocked_by: [01-rust-models-expansion]
---

# Ticket 04: 实现播放列表、磁力解析与做种接口

## Goal
在 `RqbitClient` 中实现：
- `getGlobalPlaylist() -> Future<String>` (GET /torrents/playlist)
- `getGlobalPlaylistUrl() -> String`
- `getTorrentPlaylist(int id) -> Future<String>` (GET /torrents/{id}/playlist)
- `getTorrentPlaylistUrl(int id) -> String`
- `resolveMagnet(String magnetUri, {Duration? timeout}) -> Future<Uint8List>` (POST /torrents/resolve_magnet)
- `createTorrent(String path, {String output, List<String>? trackers, String? name}) -> Future<dynamic>` (POST /torrents/create)

## Acceptance Criteria
- 在 `lib/client.dart` 实现方法。
- 在 `test/client_test.dart` 中测试并通过。
