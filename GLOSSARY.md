# GLOSSARY.md (领域统一语言词汇表)

> **规范定义**：本项目严格遵循 Matt Pocock 单上下文领域建模规范 (`docs/agents/domain.md`)。  
> 本词汇表定义 `rqbitx` 跨平台 Flutter / Rust 双语代码库中的核心领域概念、实体名词与技术接缝术语，作为开发、测试与 Agent 协作的**唯一事实术语来源**。

---

## 1. 核心架构与宿主接缝 (Core Architecture & Seams)

### RqbitServer
- **定义**：Dart 层的单实例核心控制器，统辖底层原生守护进程的生命周期，同时直接继承 `RqbitClient`。
- **职责**：执行 `start()`, `stop()`, `current()`, `startOrAttach()`，并向外暴露所有 1:1 librqbit REST API 方法。
- **不变式**：一个运行期 App 仅允许存在一个活动的 `RqbitServer`；调用 `stop()` 必须级联释放网络连接池。

### RqbitClient
- **定义**：基于 `dio` 实现的强类型 HTTP 客户端。
- **职责**：封装所有向本地守护进程 (`http://127.0.0.1:<port>`) 发送的 REST 请求，收敛 BaseUrl 管理、请求超时、异常包装与反序列化。

### FFI Seam (C-ABI 接缝)
- **定义**：Dart 与 Rust 之间的极薄原生通信边界。
- **范围**：仅包含 6 个底层函数：`rqbit_start`, `rqbit_stop`, `rqbit_is_running`, `rqbit_get_port`, `rqbit_last_error`, `rqbit_free_str`。所有业务全部走本地 HTTP REST，严禁在 FFI 层穿透复杂结构体。

### CatchUnwind Boundary (Panic 隔离带)
- **定义**：Rust 导出函数中的绝对防御机制。
- **规范**：每一个 `extern "C"` 函数体内部必须由 `std::panic::catch_unwind` 完整包裹，Rust 运行期的任何 panic 必须被截获并转换为错误码或错误字符串，严禁穿透 C-ABI 击穿 Flutter 宿主进程。

---

## 2. 跨平台沙箱与运行时环境 (Platform & Sandbox Runtime)

### WebPKI Verifier Fallback (零 JNI 纯 Rust TLS)
- **定义**：Android 移动平台下的纯 Rust TLS 根证书验证体系。
- **机制**：通过 Cargo `[patch.crates-io]` 接管 `rustls-platform-verifier`，切断 Android 默认的 Java JNI `TrustManager` 依赖，重定向至静态内嵌 Mozilla 根证书库（`webpki-root-certs`），防止在没有 `JavaVM` 注入的原生库中触发 SIGSEGV。

### DHT Persistence Sandbox (DHT 持久化沙箱)
- **定义**：Kademlia DHT 路由表持久化文件的安全路径收敛机制。
- **机制**：Android 等移动端不存在 Linux 桌面规范的 `$HOME` 或 XDG 目录。必须显式将持久化路径重定向至 `<download_dir>/.rqbit/dht.json` 并由 Rust 侧预先递归创建父目录，彻底解决启动时的崩溃缺陷。

### Hot Restart Persistence (热重启自愈)
- **定义**：开发模式下 Flutter 触发 Hot Restart 时，底层 Rust 守护进程常驻不退出、Dart 侧毫秒级重连的自愈机制。
- **实现**：Rust 导出无副作用的 `rqbit_get_port()`；Dart 侧在重启时不杀死 Rust 进程，通过 `RqbitServer.startOrAttach()` 探测活跃端口并快速恢复状态。

---

## 3. BitTorrent 领域概念与模型契约 (BitTorrent Domain & DTOs)

### InfoHash
- **定义**：BitTorrent 元数据（`info` 字典）的 20 字节 SHA-1 哈希值（v1）或 32 字节 SHA-256 哈希值（v2）。
- **用途**：全网唯一标识一个种子 Swarm 群，在客户端中以 40 位或 64 位十六进制小写字符串表示。

### TorrentId
- **定义**：librqbit 会话内为每个种子任务分配的局部自增整数索引（`0, 1, 2...`）。
- **用途**：librqbit HTTP REST 路由的常用资源标识符（如 `/torrents/{id}`）。

### Selective File Stream (按需切片下载流控)
- **定义**：针对移动端存储受限场景制定的防爆盘流控策略。
- **机制**：种子任务初始创建时默认指定 `update_only_files: []`，只解析和拉取元数据，不下载任何数据分片；仅当用户点击特定文件播放时，才动态更新为 `update_only_files: [file_idx]`。

### Piece & Bitfield (分片与位图)
- **定义**：种子文件被分割的固定大小（通常 16KB ~ 4MB）数据块，以及记录本地已拥有分片状态的二进制位图。
- **服务接口**：通过 `/torrents/{id}/haves/bytes`（原始二进制）或 `/torrents/{id}/haves/svg`（可视化矢量进度图）暴露给调用方。

---

## 4. UI 交互设计系统 (Design System)

### Bento Grid (Pure Flat 便当盒设计)
- **定义**：基于扁平化容器卡片流的信息架构规范。
- **特点**：无边框（Border-free）、零阴影（Zero Shadow）、22px 柔和圆角、完全响应原生 `Theme.of(context)` 的明暗自适应。

### Dynamic Metadata Polling (元数据感知轮询)
- **定义**：针对磁力链接解析阶段的异步状态轮询器。
- **行为**：在元数据尚未就绪时呈现优雅等待状态，后台以指数退避/定时间隔查询任务详情，一旦文件列表（`files`）解析完成立即驱动 UI 展开文件列表与播放入口。
