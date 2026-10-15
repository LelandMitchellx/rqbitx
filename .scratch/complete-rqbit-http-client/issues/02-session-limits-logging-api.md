---
status: closed
blocked_by: [01-rust-models-expansion]
---

# Ticket 02: 实现会话监控、限速与日志接口

## Goal
在 `RqbitClient` 中实现：
- `getServerInfo() -> Future<ServerInfo>` (GET /)
- `getSessionStats() -> Future<SessionStatsSnapshot>` (GET /stats)
- `getLimits() -> Future<LimitsConfig>` (GET /torrents/limits)
- `updateLimits(LimitsConfig limits) -> Future<void>` (POST /torrents/limits)
- `setRustLog(String rustLog) -> Future<void>` (POST /rust_log)

## Acceptance Criteria
- 在 `lib/client.dart` 实现对应方法。
- 在 `test/client_test.dart` 中添加 MockDaemon 单元测试并通过。
