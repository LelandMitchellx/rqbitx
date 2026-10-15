# 04: Minimal Dart API

Status: open
Type: prototype
Blocked by: 01

## Question
Dart 侧最简控制器 `RqbitServer` 的 API 应该如何设计，既保证易用性又杜绝泄露原生指针或冗余状态？

### 待决策点
- `RqbitServer.start({required String downloadDir, String? bindAddr})` 的异步/同步包装
- 异常模型：定义强类型 `RqbitException` 统一承载原生错误信息
- `server.url`（如 `http://127.0.0.1:45678`）与 `server.stop()` 的幂等性与资源自动清理机制
