# 0004. 基于 MediaKit 与 rqbit 本地 HTTP 范围切片流的视频播放集成架构

- **状态**: 已接受 (accepted)
- **日期**: 2026-10-15

## 背景

在 BitTorrent 离线与流媒体应用场景中，用户通常需要通过磁力链接（Magnet Link）或种子文件快速添加下载任务，并在文件未完全下载完成时，实现类似在线视频的“边下边播”实时流媒体播放能力。

在底层，`rqbit` 原生引擎通过其内置的 HTTP REST 服务提供了流式传输端点：
`GET /torrents/{id_or_infohash}/stream/{file_idx}`。该端点具有以下特性：
1. **HTTP Range 支持**：完全实现 `Accept-Ranges: bytes` 与 `Content-Range`，支持多媒体播放器进行任意时间轴 Seek 跳转。
2. **分片优先级动态调度**：当播放器请求某个字节区间时，引擎会自动提升对应文件数据块（Piece）的下载优先级，优先从 Swarm 网络或 Peer 节点请求所需数据。
3. **元数据延迟等待**：对于刚添加的磁力链接，请求流式端点会自动等待 metadata 解析完成并建立数据通道。

为在 Flutter 客户端验证这一端到端全链路，需要接入一个功能完善、性能优异且支持全平台的视频播放核心。

## 决策

我们选择接入 [media-kit](https://github.com/Predidit/media-kit)（基于 `libmpv` 的现代化跨平台媒体播放框架），并在 `example` 演示工程中实现基于 Bento Box 界面规范的流播放集成：

1. **核心库零侵入与职责单一解耦**：
   - 保持 `rqbitx` 插件本身的极简与单一职责（仅专注 Rust 引擎的生命周期启动、停止、配置与端口接管）。
   - 坚决不在 `rqbitx` 核心库中强依赖任何音视频解码包或重量级网络库，所有播放器与流媒体业务调度仅在 `example/` 应用层组合验证。
2. **MediaKit 跨平台依赖选型**：
   - 在 `example/pubspec.yaml` 中引入 `media_kit`、`media_kit_video` 与 `media_kit_libs_video` 平台原生伞包。
   - 伞包原生囊括 Android（arm64-v8a, armeabi-v7a, x86_64, x86）及 Windows 平台的预编译 `libmpv` 原生库，杜绝手动集成 C++ 动态链接库的繁琐配置。
   - 在 Flutter 根入口全局初始化：`MediaKit.ensureInitialized()`。
3. **极简 HTTP 任务添加与自动媒体寻址**：
   - 客户端通过标准 `HttpClient` 向本地 `POST /torrents?overwrite=true` 发送磁力链接字符串。
   - 解析返回的 `ApiAddTorrentResponse` JSON：
     - 提取 `id` 或 `details.info_hash` 作为任务唯一标识。
     - 若已解析文件列表，自动遍历并命中首个音视频格式（`.mp4`, `.mkv`, `.webm`, `.avi`, `.mov`, `.ts`）对应的 `file_idx`；否则缺省指向索引 0。
     - 组装播放直连 URL：`http://127.0.0.1:<port>/torrents/<id_or_infohash>/stream/<file_idx>`。
4. **底部抽屉弹窗（Modal Bottom Sheet）按需挂载播放器**：
   - 首屏默认保持纯净紧凑，未添加任务前不常驻显示播放器。
   - 解析出种子文件列表后，过滤音视频文件并提供「播放」操作；点击后通过 `showModalBottomSheet` 呼出 16:9 播放面板。
   - 弹窗关闭时自动调用 `_player.stop()` 释放解码与网络资源，避免常驻后台资源损耗。

## 结果与影响

- **收益（正面）**：
  - 成功走通“磁力解析 -> rqbit 调度优先下载 -> 本地 HTTP 范围切片流 -> libmpv 硬件解码播放”端到端链路。
  - Android Debug APK 顺利编译通过（Gradle 打包用时 60.5s），同时适配 Windows 与 Android 平台。
  - 验证了 `rqbitx` 作为底层独立内核搭配任意业务播放器的可组合性。
- **代价（负面）**：
  - `media_kit` 的 Android 原生库会增加 APK 体积（约 30MB+ libmpv 动态库）；若线上生产包有体积敏感度要求，可按 CPU 架构拆包（`--split-per-abi`）。
