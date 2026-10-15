---
id: 03
title: 封装按需切片下载流控 (update_only_files) 与实时速率模型接口
status: completed
blocked_by: [02]
---

## 目标
在 `RqbitClient` 中实现对 `POST /torrents/{id}/update_only_files` 与 `GET /torrents/{id}/stats/v1` 的封装，实现按需下载防爆盘与速度监控。

## 核心接口
1. `Future<void> updateOnlyFiles(int id, List<int> fileIndices)`：
   - POST `/torrents/{id}/update_only_files`
   - Payload: `{"only_files": [0, 1]}`
2. `Future<TorrentStats> getTorrentStats(int id)`：
   - GET `/torrents/{id}/stats/v1`
   - 返回强类型 `TorrentStats`，含实时瞬时速率 `Speed`。

## 验收标准 (Acceptance Criteria)
1. 客户端支持防爆盘：添加任务后可传 `only_files: []`，并在点播时切换为单个切片索引。
2. 客户端可准确解析 `TorrentStats` 中的速率数据。
3. `flutter test` 验证通过。
