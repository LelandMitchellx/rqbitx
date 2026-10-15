---
id: 01
title: 声明 1:1 映射自 librqbit 源码的 Dart 强类型 Model 与反序列化测试
status: completed
blocked_by: []
---

## 目标
严格对照 `librqbit-9.0.1` Rust 源码结构体，声明 Dart 强类型 Model。

## 涉及源码溯源
- `librqbit/src/api.rs`: `TorrentDetailsResponse`, `TorrentDetailsResponseFile`, `TorrentListResponse`, `ApiAddTorrentResponse`
- `librqbit/src/torrent_state/stats.rs`: `TorrentStats`, `LiveStats`, `Speed`
- `librqbit/src/torrent_state/live/stats/snapshot.rs`: `StatsSnapshot`
- `librqbit/src/http_api_types.rs`: `TorrentAddQueryParams`

## 产出文件
- `lib/src/models/torrent_details.dart`
- `lib/src/models/torrent_file.dart`
- `lib/src/models/torrent_stats.dart`
- `lib/src/models/torrent_options.dart`
- `lib/models.dart` (导出模型统一入口)
- `test/models_test.dart` (反序列化单元测试)

## 验收标准 (Acceptance Criteria)
1. 所有类提供强类型构造函数、`fromJson(Map<String, dynamic> json)` 和 `toJson()`。
2. 字段命名转换（如 Rust 的 snake_case `total_bytes` 转换为 Dart 的 camelCase `totalBytes`）。
3. 容忍可选字段与 null 安全。
4. `flutter test test/models_test.dart` 通过真实 JSON 样例测试。
