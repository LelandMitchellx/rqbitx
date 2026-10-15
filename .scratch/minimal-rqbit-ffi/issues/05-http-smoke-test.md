# 05: HTTP Smoke Test

Status: open
Type: task
Blocked by: 03, 04

## Question
如何编写端到端冒烟测试，通过标准 `HttpClient` 验证 rqbit HTTP 服务被成功拉起并能响应请求？

### 验证步骤
- 调用 `RqbitServer.start()` 成功获取端口与服务 URL
- 使用 Dart 原生 `HttpClient` 发起 `GET ${server.url}/` 或 `/torrents` 请求，确认返回 200 OK
- 调用 `server.stop()` 后验证端口正常释放，再次连接立即拒绝
