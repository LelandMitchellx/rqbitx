---
status: closed
blocked_by: []
---

# Ticket 01: 补齐 librqbit 1:1 统计与配置模型

## Goal
根据 librqbit 9.0.1 源码，补齐全量接口所需的 DTO：
- `ServerInfo` (`server`, `version`, `apis`)
- `LimitsConfig` (`uploadBps`, `downloadBps`)
- `SessionStatsSnapshot` 及子统计模型 (`SessionCounters`, `AggregatePeerStats`, `ConnectStatsSnapshot`)
- `DhtStats` 及 `DhtRoutingTable`
- `PeerStatsSnapshot` 与 `PeerStats`, `PeerCounters`

## Acceptance Criteria
- 在 `lib/models/` 下实现对应的强类型类。
- 在 `lib/models.dart` 中集中导出。
- 编写 `test/models_test.dart` 针对新模型的反序列化测试全部通过。
