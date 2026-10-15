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

### 2. 启动守护进程并直接调用 API

`RqbitServer` 直接继承自 `RqbitClient`，单实例兼具后台生命周期管控与全量强类型 HTTP API：

```dart
import 'package:rqbitx/rqbitx.dart';

void main() async {
  // 1. 启动或复用常驻守护服务 (自动分配空闲端口)
  final server = await RqbitServer.startOrAttach(
    downloadDir: '/path/to/downloads',
    dhtPersistencePath: '/path/to/downloads/.rqbit/dht.json',
  );

  print('rqbit 服务运行中: ${server.url}'); // http://127.0.0.1:<port>/

  // 2. 直接通过 server 实例调用 REST API（无需额外创建 Client）
  final serverInfo = await server.getServerInfo();
  print('Server: ${serverInfo.server}, Version: ${serverInfo.version}');
}
```

### 3. 添加种子与管理下载

```dart
// 添加磁力链接
final addResponse = await server.addTorrent(
  magnetUri: 'magnet:?xt=urn:btih:...',
  options: const AddTorrentOptions(
    overwrite: false,
    listOnly: false, // 是否仅拉取元数据
  ),
);

final torrentId = addResponse.id!;

// 查询任务详情与文件列表
final details = await server.getTorrentDetails(torrentId);
print('任务名称: ${details.name}, 状态: ${details.state}');

for (final file in details.files) {
  print('文件 [${file.id}]: ${file.name} (${file.length} bytes)');
}

// 视频边下边播播放直链
final streamUrl = server.url.resolve('/torrents/$torrentId/stream/${details.files.first.id}');
print('流媒体播放地址: $streamUrl');

// 暂停与恢复
await server.pauseTorrent(torrentId);
await server.startTorrent(torrentId);

// 彻底删除任务并清理磁盘物理文件
await server.deleteTorrent(torrentId);
```

---

## 📂 纯正 Matt Pocock 架构目录规约

本项目严格遵循 Matt Pocock 单上下文工程规约（无冗余文档、单一事实来源）：

```text
rqbitx/
├── lib/                     # Dart API, Client 与 1:1 Rust 领域 DTO
├── rust/                    # Rust Native Assets 底座层与 Tokio 守护服务
├── hook/                    # Flutter Native Assets 编译钩子
├── test/                    # 单元测试与契约测试 (34/34 passing)
├── GLOSSARY.md              # 领域统一语言词汇表 (Ubiquitous Language)
├── CODING_STANDARDS.md      # Reviewer 高阶架构决策与平台安全审查标准
├── CHANGELOG.md             # 演进与修改记录全景台账 (Single Source of Truth)
├── AGENTS.md                # AI Agent 技能极简路由指针
├── docs/
│   ├── adr/                 # 架构决策记录 (ADR 0001 ~ 0010)
│   └── agents/              # Agent 基础设施配置 (domain, issue-tracker, triage)
├── .scratch/                # 敏捷需求规格 (spec.md) 与工单树 (issues/)
└── example/                 # 示例工程：纯平 Bento Grid 流媒体播放器
```

---

## 📜 决策记录与规范体系 (Standards & ADRs)

- 📖 **领域统一语言**：核心实体与名词字典定义，详见 [GLOSSARY.md](GLOSSARY.md)。
- 📋 **全景演进记录台账**：单事实来源记录历次需求、修复与重构，详见 [CHANGELOG.md](CHANGELOG.md)。
- 🛡️ **审查红线基线**：自动化测试之外的架构决策与平台安全性审查，详见 [CODING_STANDARDS.md](CODING_STANDARDS.md)。
- 📐 **架构决策记录 (ADR)**：

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
| [ADR-0009](docs/adr/0009-server-inherits-client-unified-instance.md) | RqbitServer 继承 RqbitClient 统一单实例设计 | `Accepted` | 单实例兼具守护进程生命周期与全量 REST API，联动关闭底层连接池 |
| [ADR-0010](docs/adr/0010-android-webpki-pure-rust-tls-verifier.md) | Android 静态 WebPKI 根证书与零 JNI 纯 Rust TLS 校验体系 | `Accepted` | 彻底杜绝 Android 未注入 JVM 上下文导致的崩溃 |

---

## 🔍 生产就绪性审计与路线图 (Production Status)

> 当前版本定性：**高质量原型验证与功能完备期 (Alpha / PoC)**  
> 详经严谨的代码审查，投产前必须解决移动端原生系统规约限制：

- [ ] **P0-1: 修复 Android Release 清单网络权限**：在 `main/AndroidManifest.xml` 中补齐 `INTERNET` 与 `ACCESS_NETWORK_STATE`。
- [x] **P0-2: TLS 证书去 JNI 化**：已通过 `rustls-platform-verifier` 本地 WebPKI 补丁彻底解决 Android 缺失 JNI 初始化引发的崩溃（详见 [ADR-0010](docs/adr/0010-android-webpki-pure-rust-tls-verifier.md) 与 [CODING_STANDARDS.md](CODING_STANDARDS.md)）。
- [ ] **P0-3: 本地 HTTP 服务 Bearer Token 鉴权**：守护进程生成随机 Token 校验请求头，防止本地第三方网页恶意 CSRF 删文件。
- [ ] **P0-4: 移动端专属沙盒存储**：将默认下载路径从可能被 OS 自动清空的 Cache 迁移至持久性外部沙盒目录。
- [ ] **P1-1: 移动端后台保活**：接入 Android 前台服务 (Foreground Service) 与 WakeLock，杜绝切后台被系统冻结网络。

---

## 🤝 参与贡献与许可证

- 静态分析：`flutter analyze` (零 warning/error 准入)
- 单元测试：`flutter test` (34/34 测试全量通过)

开源许可证：**MIT License**
