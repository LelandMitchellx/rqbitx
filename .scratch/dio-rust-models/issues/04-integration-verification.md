---
id: 04
title: 全链路端到端集成验证与双轴质量审查
status: completed
blocked_by: [01, 02, 03]
---

## 目标
结合真实启动的 `RqbitServer` 底座与新封装的 `RqbitClient`，验证端到端整体验收。

## 验收标准 (Acceptance Criteria)
1. 真实启动 FFI 服务，使用 `RqbitClient` 成功请求 API 并返回强类型对象。
2. `flutter test` 全量通过 (包括存量 4 个测试与新增测试)。
3. `flutter analyze` 0 errors, 0 warnings。
