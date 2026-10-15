# 📜 项目演进全景台账与变更日志 (Project Changelog & Evolution Ledger)

> 本文档完整记录了 `rqbitx` 从最初最根本的核心需求，到后续所有架构提案、体验演进、Bug 修复及重构优化的全流程溯源记录。
> **铁律规约**：后续任何新增需求、Bug 修复或架构优化，提交代码时必须同步向本文档追加更新。

---

## 🎯 初始最根本需求 (The Genesis Requirement)

- **项目起源**：旧参考工程（`code/rqbit`）存在 1148 行单文件、复杂的 EventBus 状态机、非官方强类型模型以及紧耦合的逻辑体系，扩展与维护成本极高。
- **最初也是最核心的根本目标**：
  > **“抛弃历史包袱，重新做一个最小的 FFI 插件，在 Flutter 中拉起 librqbit 的 HTTP 服务，以保证极致的可控性；其余一切业务交互完全由标准 HTTP/JSON 接口承接。”**
- **不可违背的设计基石**：
  1. **极简 FFI 接缝**：Rust 侧仅保留最基础的生命周期管控（`start`、`stop`、`get_port`），杜绝复杂业务渗入 C-ABI；
  2. **绝对安全隔离**：所有 Rust FFI 接口必须被 `catch_unwind` 隔离，Rust 崩溃不能导致 Flutter 宿主进程闪退；
  3. **Flutter Native Assets**：弃用老式 Platform Channel，采用 Dart 原生 Native Assets 自动化构建体系。

---

## 🕒 演进时间线与全量修改记录 (Chronological Modification Records)

| 阶段 | 类型 | 核心内容概要 | 关联凭证 (ADR / PRD / Commit) |
| :---: | :---: | :--- | :--- |
| **01** | `[根本需求]` | 搭建 Native Assets 工具链与极简 FFI 启停核心 | [ADR-0001](docs/adr/0001-minimal-ffi-lifecycle-seam.md) · `.scratch/minimal-rqbit-ffi/` |
| **02** | `[体验提案]` | 设计纯平 Bento Grid 无边框卡片设计系统 | [ADR-0002](docs/adr/0002-bento-grid-borderless-ui-design-system.md) |
| **03** | `[Bug 修复]` | 修复 Android 交叉编译缺少 `rust-toolchain.toml` 报错 | `rust/rust-toolchain.toml` |
| **04** | `[Bug 修复]` | 修复 Android 缺少 XDG 环境变量导致 DHT 启动 Panic | [ADR-0003](docs/adr/0003-dht-persistence-path-isolation.md) |
| **05** | `[核心提案]` | 集成 media-kit 实现边下边播与底部弹窗播放器 | [PRD-0001](docs/prd/0001-torrent-streaming-player-ux.md) · [ADR-0004](docs/adr/0004-media-kit-torrent-video-streaming.md) |
| **06** | `[Bug 修复]` | 解决 Flutter Hot Restart 导致 rqbit 后台服务中断 | [ADR-0005](docs/adr/0005-hot-restart-daemon-persistence.md) |
| **07** | `[UI 重构]` | 原生 ThemeData 三态切换、URL 格式修复与控制台收敛 | [ADR-0006](docs/adr/0006-dark-light-theme-switching.md) |
| **08** | `[业务提案]` | 接入任务与本地物理磁盘切片彻底删除功能 | [PRD-0001 §3.5](docs/prd/0001-torrent-streaming-player-ux.md) |
| **09** | `[架构提案]` | 抽象 Dio 官方 HTTP 客户端与 1:1 Rust 强类型领域模型 | [PRD-0002](docs/prd/0002-feature-backlog-and-dio-rust-models.md) · [ADR-0007](docs/adr/0007-dio-http-client-and-rust-dto-mapping.md) · `d2ec8fa` |
| **10** | `[结构优化]` | 扁平化 lib 目录结构，消除 `lib/src/` 冗余嵌套 | Commit [`5cf9ad1`](https://github.com/LelandMitchellx/rqbitx/commit/5cf9ad1) |
| **11** | `[业务提案]` | 全量对齐 librqbit 官方 HTTP API 与高级功能模型 | [ADR-0008](docs/adr/0008-complete-librqbit-http-api.md) · Commit [`95e22da`](https://github.com/LelandMitchellx/rqbitx/commit/95e22da) |
| **12** | `[工程沉淀]` | 生产就绪度安全审计、生成 README.md 与 GitHub 推送 | Commit [`886efc3`](https://github.com/LelandMitchellx/rqbitx/commit/886efc3) |
| **13** | `[架构重构]` | `RqbitServer` 继承 `RqbitClient`，实现单实例统一设计 | [ADR-0009](docs/adr/0009-server-inherits-client-unified-instance.md) · Commit [`be16781`](https://github.com/LelandMitchellx/rqbitx/commit/be16781) |

---

## 📝 阶段详细修改记录 (Detailed Stage Ledger)

### 阶段 01：极简 FFI 启动器与 Native Assets 工具链搭建
- **类型**：`[根本需求初始化]`
- **触发背景**：用户要求重做最小可控的 rqbit 插件，仅在 Flutter 中拉起 HTTP 服务。
- **改动详情**：
  1. 引入 WebPKI 离线根证书补丁（`rust/rustls-platform-verifier`），避免 Android 移动端依赖 JVM JNI 报错；
  2. 编写 `rust/src/lib.rs`，仅导出 `rqbit_start`、`rqbit_stop`、`rqbit_is_running`、`rqbit_last_error` 4 个 C-ABI 接口，入参采用 JSON CString 序列化；
  3. 配置 `hook/build.dart`，启用 Flutter 原生 Native Assets 自动化构建；
  4. Dart 端编写极简 `RqbitServer` 句柄，仅 ~85 行代码；
  5. 编写首批集成测试 `test/rqbitx_test.dart`。
- **凭证**：[ADR-0001](docs/adr/0001-minimal-ffi-lifecycle-seam.md) · `.scratch/minimal-rqbit-ffi/`

---

### 阶段 02：Bento Grid 纯平卡片式设计系统与 Example 骨架
- **类型**：`[体验提案]`
- **触发背景**：为了在 Flutter 移动端直观验证服务运行状态，需要设计一个现代、清爽的演示界面。
- **改动详情**：
  1. 搭建 `example/` 工程并引入 `rqbitx`；
  2. 采用现代 Bento Grid（便当盒）布局，设计大圆角、状态徽章、无边框卡片；
  3. 提供服务启停按钮与实时 HTTP 请求日志响应输出框。
- **凭证**：[ADR-0002](docs/adr/0002-bento-grid-borderless-ui-design-system.md)

---

### 阶段 03：修复 Android 交叉编译缺少工具链配置
- **类型**：`[Bug 修复]`
- **问题症状**：在编译 Android APK 时，`native_toolchain_rust` 校验失败抛出 `RustValidationException`，提示缺少 `rust/rust-toolchain.toml`。
- **改动详情**：
  1. 创建 `rust/rust-toolchain.toml`；
  2. 锁定 Rust 通道版本为 `1.98.0`；
  3. 显式声明 targets：`x86_64-pc-windows-msvc`, `aarch64-linux-android`, `armv7-linux-androideabi`, `i686-linux-android`, `x86_64-linux-android`。
- **结果**：成功产出各架构 `librqbitx.so`，并打通 APK 构建。

---

### 阶段 04：修复 Android 缺少 XDG 环境变量导致 DHT 启动 Panic
- **类型**：`[Bug 修复]`
- **问题症状**：Android 真机启动服务直接闪退报 Error -10。原因是 librqbit 默认的 `PersistentDht` 会调用 `get_configuration_directory("dht")`，但移动端不存在 Linux XDG 环境变量或 `$HOME`。
- **改动详情**：
  1. 修改 `rust/src/lib.rs` 的 `RqbitStartConfig`，增加 `dht_persistence` 字段；
  2. 默认重定向到 `<download_dir>/.rqbit/dht.json`，且自动预先创建父级目录；
  3. 支持传入空字符串 `""` 显式禁用 DHT 持久化缓存；
  4. 在 `test/rqbitx_test.dart` 补充多场景测试用例。
- **凭证**：[ADR-0003](docs/adr/0003-dht-persistence-path-isolation.md)

---

### 阶段 05：集成 media-kit 实现边下边播与底部弹窗播放器
- **类型**：`[核心功能提案]`
- **触发背景**：用户提出需求：“支持磁力链接输入并边下边播视频”。
- **改动详情**：
  1. 集成流媒体播放器，为避免 Flutter 依赖冲突，采用 `Predidit/media-kit` git HEAD 版本；
  2. 改造交互体验：启动 App 时自启动服务，创建种子后动态定时轮询元数据；
  3. 自动识别媒体文件类型（`mp4`, `mkv`, `avi` 等），呈现独立“播放”按钮；
  4. 采用沉浸式 `showModalBottomSheet` 模态弹窗嵌入视频播放器，关闭弹窗自动停止播放。
- **凭证**：[PRD-0001](docs/prd/0001-torrent-streaming-player-ux.md) · [ADR-0004](docs/adr/0004-media-kit-torrent-video-streaming.md)

---

### 阶段 06：解决 Flutter Hot Restart 导致 rqbit 后台服务中断
- **类型**：`[开发体验 Bug 修复]`
- **问题症状**：开发者在 Flutter 执行 Hot Restart（热重启）时，Dart 内存与生命周期重置，导致正在运行的后台服务被强制停止，或者 Dart 重载后丢失服务端口信息无法重新连接。
- **改动详情**：
  1. Rust 侧导出 `rqbit_get_port()` 接口；
  2. Dart 端增加 `RqbitServer.current()` 探活静态方法，以及 `RqbitServer.startOrAttach()` 自愈方法；
  3. Example 中移除 `dispose()` 里的强制 stop 调用，App 启动时优先尝试毫秒级重新挂接到已有守护进程；
  4. 保持开发期调试过程下载连续性。
- **凭证**：[ADR-0005](docs/adr/0005-hot-restart-daemon-persistence.md)

---

### 阶段 07：原生 ThemeData 三态切换与服务控制台收敛
- **类型**：`[UI 重构与细节修复]`
- **触发背景**：用户反馈视觉体验有杂音，且流播放地址存在 URL 斜杠解析异常。
- **改动详情**：
  1. 修复流直链 `FormatException`：使用 `server.url.resolve(...)` 规范拼接；
  2. 移除冗余的 `SafeArea` 与自定义 `BentoColors` 类，直接消费原生 `Theme.of(context)`；
  3. 支持 System / Light / Dark 三态无缝切换；
  4. 将服务状态、断开/启动控制、端口展示、URL 复制和 HTTP 探活收敛为一个纯平“服务管理”大卡片。
- **凭证**：[ADR-0006](docs/adr/0006-dark-light-theme-switching.md)

---

### 阶段 08：接入任务与本地物理磁盘切片彻底删除功能
- **类型**：`[业务功能提案]`
- **触发背景**：用户提出需要能够主动清理已创建的种子任务以及占用的磁盘空间。
- **改动详情**：
  1. 接入 librqbit 的 `POST /torrents/{id}/delete` 端点（不仅停止 session，还递归物理删除已下载文件）；
  2. 在任务卡片右上角和操作区增加删除按钮；
  3. 增加红色警示的二次确认 Dialog，防止误删文件；
  4. 在 `test/rqbitx_test.dart` 补充路由与删除行为测试。
- **凭证**：[PRD-0001 §3.5](docs/prd/0001-torrent-streaming-player-ux.md)

---

### 阶段 09：抽象 Dio 客户端与 1:1 Rust 强类型领域模型
- **类型**：`[核心架构提案]`
- **触发背景**：审计老工程后，用户明确要求：“使用 Dio 封装客户端，领域模型必须与 librqbit Rust 源码 1:1 映射”。
- **改动详情**：
  1. 引入 `dio: ^5.9.0`，编写 `RqbitClient`，统一处理连接超时、异常转换与 JSON 编解码；
  2. 对照 Rust 源码 (`http_api_types.rs`, `api.rs`, `stats.rs`) 编写 1:1 强类型 Dart 模型；
  3. 编写 `test/client_test.dart`（8 个契约测试）和 `test/models_test.dart`（5 个反序列化测试）；
  4. 固化需求矩阵文档。
- **凭证**：[PRD-0002](docs/prd/0002-feature-backlog-and-dio-rust-models.md) · [ADR-0007](docs/adr/0007-dio-http-client-and-rust-dto-mapping.md) · Commit `d2ec8fa`

---

### 阶段 10：扁平化 lib 目录结构
- **类型**：`[结构重构提案]`
- **触发背景**：用户要求：“把 client.dart 和 models 移动到 lib 下面，不要套在 lib/src 里”。
- **改动详情**：
  1. 移动 `lib/src/client.dart` → `lib/client.dart`；
  2. 移动 `lib/src/models/` → `lib/models/`；
  3. 删除空的 `lib/src/` 文件夹；
  4. 更新所有相对引用，保持 20 个测试全绿。
- **凭证**：Commit [`5cf9ad1`](https://github.com/LelandMitchellx/rqbitx/commit/5cf9ad1)

---

### 阶段 11：全量对齐 librqbit 官方 HTTP API 与高级功能模型
- **类型**：`[业务全量提案]`
- **触发背景**：用户要求：“把 RqbitClient 完善一下，把 rqbit 的 HTTP 接口都加上”。
- **改动详情**：
  1. 对照 librqbit 官方源码，补齐 `ServerInfo`, `LimitsConfig`, `SessionStatsSnapshot`, `DhtStats`, `PeerStatsSnapshot` 等领域模型；
  2. 在 `RqbitClient` 全量新增 10+ 核心 API（`getServerInfo`, `getSessionStats`, `getLimits`, `updateLimits`, `setRustLog`, `getDhtStats`, `getDhtTable`, `forgetTorrent`, `addPeers`, `getPeerStats`, `getTorrentMetadata`, `getTorrentHavesBytes/Svg`, `getGlobalPlaylist`, `getTorrentPlaylist`, `resolveMagnet`, `createTorrent` 等）；
  3. 扩充契约测试，测试用例增加到 33 个。
- **凭证**：[ADR-0008](docs/adr/0008-complete-librqbit-http-api.md) · Commit [`95e22da`](https://github.com/LelandMitchellx/rqbitx/commit/95e22da)

---

### 阶段 12：生产就绪度安全审计与 GitHub 推送
- **类型**：`[工程化与质量保证]`
- **触发背景**：用户提议：“拉个 subagent 调查一下我们这个项目可以用于生产了吗？然后生成 readme 并提交推送”。
- **改动详情**：
  1. 派发 Reviewer 子 Agent 进行只读审计，产出 P0 阻断清单（Android INTERNET 权限、HTTPS Tracker JNI 缺失、127.0.0.1 HTTP 零鉴权 CSRF 隐患、Rust 1.98 通道非标语法）与 P1 风险清单；
  2. 撰写标准化 `README.md`，绘制 ASCII 架构拓扑图、快速上手、ADR 索引与 Roadmap；
  3. 修复 SSH config 别名并顺利推送至 `LelandMitchellx/rqbitx` master 分支。
- **凭证**：Commit [`886efc3`](https://github.com/LelandMitchellx/rqbitx/commit/886efc3)

---

### 阶段 13：RqbitServer 继承 RqbitClient 统一单实例设计
- **类型**：`[架构优化提案]`
- **触发背景**：用户提议：“想了一下还是把 RqbitServer 继承 RqbitClient 可以吗，只创建一个实例就能用 RqbitClient”。
- **改动详情**：
  1. 改造 `class RqbitServer extends RqbitClient`，单实例兼具守护进程生命周期管控与全量 REST API 调用；
  2. 在 `server.stop()` 时自动联动触发 `dio.close(force: true)` 释放底层 HTTP 连接池；
  3. 彻底重构 `example/lib/main.dart`，移除冗余的 `_client` 变量，简化 9 处调用链路；
  4. 扩充单实例直接调用测试，全包测试通过数达到 34 个。
- **凭证**：[ADR-0009](docs/adr/0009-server-inherits-client-unified-instance.md) · Commit [`be16781`](https://github.com/LelandMitchellx/rqbitx/commit/be16781)

---

## 📌 持续维护规范 (Protocol Going Forward)

为了永久保持项目改动透明、清晰可追溯，团队（包含 AI 与人类开发者）必须遵循以下规约：

1. **先登记后提交**：任何新增需求、Bug 修复或重构，均需在 `CHANGELOG.md` 中按阶段编号追加对应条目；
2. **要素完备**：条目必须包含 **类型**、**产生背景**、**修改内容**、**关联凭证 (ADR/PRD/Commit)**；
3. **架构变动必有 ADR**：凡涉及类关系调整、设计模式变更或基础设施变动，必须同步在 `docs/adr/` 建立 ADR 文档。
