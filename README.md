# rqbitx

> 🚀 **下一代 Flutter 原生 Rust BitTorrent 引擎插件与边下边播流媒体解决方案**  
> 基于 **Flutter Native Assets** 深度集成 **librqbit 9.0.1**，提供极致轻量的 C-ABI 极简接缝、Hot Restart 常驻恢复、1:1 对齐官方的 Dart 强类型领域模型与纯平 Bento Grid 播放器。

---

## 🌟 核心架构特性 (Key Highlights)

- ⚡ **Flutter Native Assets 原生构建**：基于 `native_toolchain_rust` 与 `hook/build.dart` 自动化交叉编译 Rust 动态库 (`.so` / `.dll` / `.dylib`)，摆脱传统 Platform Channel 序列化开销与冗长 JNI 代码。
- 🔄 **Hot Restart 守护常驻与自动附着**：开发期执行 Flutter Hot Restart 服务不中断；重载后通过 `RqbitServer.startOrAttach()` 毫秒级探测并重新附着到活跃的 Rust 守护进程（详见 [ADR-0005](docs/adr/0005-hot-restart-daemon-persistence.md)）。
- 📡 **1:1 官方全量 REST 客户端**：基于轻量 Dio 库封装 `RqbitClient`，对齐官方 `librqbit` 9.0.1 全功能接口（服务元数据、全局统计、DHT 路由表、Peer 连接拓扑、限速调优、M3U8 播放列表与磁力解析，详见 [ADR-0007](docs/adr/0007-dio-http-client-and-rust-dto-mapping.md) 与 [ADR-0008](docs/adr/0008-complete-librqbit-http-api.md)）。
- 📦 **1:1 Rust 强类型领域模型**：所有 DTO (`TorrentDetails`, `TorrentStats`, `SessionStatsSnapshot`, `DhtStats`, `PeerStatsSnapshot` 等）直接衍生自 Rust 源码结构，具备安全空容错与 100% 契约测试覆盖。
- 🎬 **边下边播与纯平 Bento 设计**：内置集成高性能 `media_kit` 视频播放器，通过 HTTP 范围请求流式直连 `/torrents/{id}/stream/{file_idx}`；采用零边框、无阴影的现代纯平 Bento Grid 交互范式（详见 [ADR-0002](docs/adr/0002-bento-grid-borderless-ui-design-system.md) 与 [ADR-0004](docs/adr/0004-media-kit-torrent-video-streaming.md)）。
- 🛡️ **隔离设计与单向依赖**：Rust 仅负责基础生命周期管控 (`start`, `stop`, `get_port`) 与 panic 隔离；所有复杂下载业务逻辑均通过标准 HTTP/JSON 解耦，永不挂死主线程。

---

## 🏗️ 架构分层设计

```text
┌────────────────────────────────────────────────────────┐
│                   Flutter UI 应用层                    │
│   (example/lib/main.dart: 纯平 Bento Box、深浅色模式)    │
│   (media_kit 视频播放器: 直连本地 HTTP Stream 流式播放)   │
└───────────────────────────▲────────────────────────────┘
                            │ HTTP (Dio)
┌───────────────────────────┴────────────────────────────┐
│               Dart API / Client 领域层                 │
│   lib/rqbitx.dart: RqbitServer 进程守护与 Hot Restart   │
│   lib/client.dart: RqbitClient 官方 REST 接口封装        │
│   lib/models/    : 1:1 对齐 librqbit Rust 源码 DTO     │
└───────────────────────────▲────────────────────────────┘
                            │ C-ABI (Dart FFI)
┌───────────────────────────┴────────────────────────────┐
│              Rust Native Assets 底座层                 │
│   rust/src/lib.rs: C-ABI 极简生命周期接缝与 Panic 隔离    │
│   Tokio Runtime  : 独立后台线程池，监听 127.0.0.1 动态端口 │
│   librqbit 9.0.1 : 现代异步 BitTorrent v1/v2 下载引擎   │
└────────────────────────────────────────────────────────┘
```

---

## 🚀 快速上手 (Quick Start)

### 1. 引入依赖
在你的 `pubspec.yaml` 中引入 `rqbitx` 与 `dio`：

```yaml
dependencies:
  rqbitx:
    path: ../rqbitx # 或 git 引用
  dio: ^5.9.0
```

### 2. 启动或附着后台守护进程

```dart
import 'package:rqbitx/rqbitx.dart';
import 'package:rqbitx/client.dart';

void main() async {
  // 1. 启动或复用常驻守护服务 (自动分配空闲端口)
  final server = await RqbitServer.startOrAttach(
    downloadDir: '/path/to/downloads',
    dhtPersistencePath: '/path/to/downloads/.rqbit/dht.json',
  );

  print('rqbit 服务运行中: ${server.url}'); // http://127.0.0.1:<port>/

  // 2. 初始化官方 REST 客户端
  final client = RqbitClient(server.url);

  // 3. 检查服务端信息
  final serverInfo = await client.getServerInfo();
  print('Server: ${serverInfo.server}, Version: ${serverInfo.version}');
}
```

### 3. 添加种子与管理下载

```dart
// 添加磁力链接
final addResponse = await client.addTorrent(
  magnetUri: 'magnet:?xt=urn:btih:...',
  options: const AddTorrentOptions(
    overwrite: false,
    listOnly: false, // 是否仅拉取元数据
  ),
);

final torrentId = addResponse.id!;

// 查询任务详情与文件列表
final details = await client.getTorrentDetails(torrentId);
print('任务名称: ${details.name}, 状态: ${details.state}');

for (final file in details.files) {
  print('文件 [${file.id}]: ${file.name} (${file.length} bytes)');
}

// 视频边下边播播放直链
final streamUrl = server.url.resolve('/torrents/$torrentId/stream/${details.files.first.id}');
print('流媒体播放地址: $streamUrl');

// 暂停与恢复
await client.pauseTorrent(torrentId);
await client.startTorrent(torrentId);

// 彻底删除任务并清理磁盘物理文件
await client.deleteTorrent(torrentId);
```

### 4. 获取全局会话统计与限速管理

```dart
// 获取全局网络吞吐与 Peer 统计
final stats = await client.getSessionStats();
print('下载速率: ${stats.counters.fetchedBytes.humanReadable}/s');
print('连接 Peers 数: ${stats.aggregatePeerStats.live}');

// 调整会话级限速带宽 (字节/秒)
await client.updateLimits(
  const LimitsConfig(
    downloadBps: 10 * 1024 * 1024, // 10 MB/s
    uploadBps: 2 * 1024 * 1024,     // 2 MB/s
  ),
);
```

---

## 📂 项目目录规约

```text
rqbitx/
├── lib/
│   ├── rqbitx.dart          # FFI C-ABI 极简接缝与 RqbitServer 生命周期管理
│   ├── client.dart          # 基于 Dio 封装的官方 RqbitClient REST API
│   ├── models.dart          # 领域模型集中导出入口
│   └── models/              # 1:1 Rust 领域 DTO
│       ├── server_info.dart       # 服务元数据与 API 路由
│       ├── torrent_details.dart   # 种子详情与文件清单
│       ├── torrent_stats.dart     # 实时传输速率与分片进度
│       ├── session_stats.dart     # 全局会话与吞吐统计
│       ├── dht_stats.dart         # DHT 节点与路由表
│       ├── peer_stats.dart        # Peer 延迟、客户端标识与计数器
│       └── limits_config.dart     # 全局限速配置
├── rust/
│   ├── src/lib.rs           # 极简 Rust C-ABI 导出与 Tokio 守护服务
│   └── Cargo.toml           # librqbit 依赖配置
├── hook/
│   └── build.dart           # Flutter Native Assets 编译钩子
├── test/
│   ├── rqbitx_test.dart     # 真实 FFI 与底层端点测试
│   ├── client_test.dart     # Dio 客户端全量 Contract 契约测试
│   └── models_test.dart     # 领域模型反序列化契约测试
├── docs/
│   ├── adr/                 # 架构决策记录 (ADR 0001 ~ 0008)
│   └── prd/                 # 产品需求文档 (PRD 0001 ~ 0002)
└── example/                 # 示例工程：纯平 Bento Grid 流媒体播放器
```

---

## 📜 架构决策记录 (Architecture Decision Records)

本项目遵循严谨的工程架构决策跟踪体系，全量设计均沉淀为 ADR：

| 编号 | 标题 | 状态 | 核心价值 |
| :--- | :--- | :---: | :--- |
| [ADR-0001](docs/adr/0001-minimal-ffi-lifecycle-seam.md) | 极简 FFI 生命周期接缝架构 | `Accepted` | 仅保留启停端口 3 个导出，业务完全交由 HTTP，防内存泄漏 |
| [ADR-0002](docs/adr/0002-bento-grid-borderless-ui-design-system.md) | 纯平无边框 Bento Grid 设计系统 | `Accepted` | 告别多层投影与嵌套框，采用现代极简大圆角扁平卡片 |
| [ADR-0003](docs/adr/0003-dht-persistence-path-isolation.md) | Android DHT 路径隔离与跨平台持久化 | `Accepted` | 解决移动端 XDG 环境变量缺失导致的启动 Panic |
| [ADR-0004](docs/adr/0004-media-kit-torrent-video-streaming.md) | 集成 media-kit 实现边下边播 | `Accepted` | 基于本地 HTTP Range 请求实现零延迟视频切片直流播放 |
| [ADR-0005](docs/adr/0005-hot-restart-daemon-persistence.md) | Flutter Hot Restart 守护服务常驻与自动重连 | `Accepted` | 解决开发期热重载导致底层服务中断的痛点，秒级自愈 |
| [ADR-0006](docs/adr/0006-dark-light-theme-switching.md) | 原生 ThemeData 驱动的深浅色三态切换 | `Accepted` | 系统/浅色/深色无缝流转，彻底删除冗余自定义颜色类 |
| [ADR-0007](docs/adr/0007-dio-http-client-and-rust-dto-mapping.md) | Dio HTTP 客户端与 1:1 Rust 领域模型 | `Accepted` | 提供强类型空安全 Dart SDK，杜绝松散 Map 解析 |
| [ADR-0008](docs/adr/0008-complete-librqbit-http-api.md) | 完整对齐 librqbit 官方 HTTP API 规范 | `Accepted` | 全量补齐会话、DHT、Peer、M3U8 等 10+ 官方高级接口 |

---

## 🔍 生产就绪性审计与路线图 (Production Status)

> 当前版本定性：**高质量原型验证与功能完备期 (Alpha / PoC)**  
> 详经严谨的代码审查，投产前必须解决移动端原生系统规约限制：

- [ ] **P0-1: 修复 Android Release 清单网络权限**：在 `main/AndroidManifest.xml` 中补齐 `INTERNET` 与 `ACCESS_NETWORK_STATE`。
- [ ] **P0-2: TLS 证书去 JNI 化**：引入纯 Rust `webpki-roots` 彻底解决 Android 缺失 JNI 初始化引发的 HTTPS Tracker 崩溃。
- [ ] **P0-3: 本地 HTTP 服务 Bearer Token 鉴权**：守护进程生成随机 Token 校验请求头，防止本地第三方网页恶意 CSRF 删文件。
- [ ] **P0-4: 移动端专属沙盒存储**：将默认下载路径从可能被 OS 自动清空的 Cache 迁移至持久性外部沙盒目录。
- [ ] **P1-1: 移动端后台保活**：接入 Android 前台服务 (Foreground Service) 与 WakeLock，杜绝切后台被系统冻结网络。

---

## 🤝 参与贡献与许可证

欢迎提交 Issue 和 Pull Request！本项目严格遵循代码格式化与规范提交：
- 静态分析：`flutter analyze` (零 warning/error 准入)
- 单元测试：`flutter test` (33/33 测试全量通过)

开源许可证：**MIT License**
