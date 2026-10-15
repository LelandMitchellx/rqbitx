# 01: Rust C-ABI Server Lifecycle

Status: claimed
Type: prototype

## Question
如何设计最简 Rust C-ABI 接口与服务生命周期管理，以确保安全启动 Tokio 运行时与 rqbit HTTP 监听，并在异常时捕获 Panic 并返回结构化错误？

### 待决策点
- C-ABI 导出函数签名（如 `rqbit_server_start`, `rqbit_server_stop`, `rqbit_server_last_error`, `rqbit_free_str`）
- 结构化 JSON 配置的最小字段集合（下载目录 `download_dir`、监听地址 `bind_addr` 等）
- 全局或 Handle 级别的 `watch::Sender` 停机信号机制与线程 `JoinHandle` 安全回收
