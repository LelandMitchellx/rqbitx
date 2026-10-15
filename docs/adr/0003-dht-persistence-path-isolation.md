# 0003. DHT 持久化路径沙箱隔离与 Android 兼容性决策

- **状态**: 已接受 (accepted)
- **日期**: 2026-10-15

## 背景

上游核心库 `librqbit` 在通过 `SessionOptions::default()` 初始化时，默认会开启 BitTorrent DHT（分布式哈希表）路由表持久化，其结构体为：
`DhtSessionConfig { persistence: Some(DhtPersistenceConfig::default()) }`。

在底层 `librqbit-dht` 的实现中，`DhtPersistenceConfig::default()` 的 `config_filename` 字段默认为 `None`。当该字段为空时，引擎会尝试通过 `PersistentDht::default_persistence_filename()` 查找操作系统级默认配置目录，内部直接调用了 `librqbit_core::directories::get_configuration_directory("dht")`。

在 Android 系统以及移动端受限沙箱中（其编译目标为 `target_os = "android"`，走非 Windows/macOS 的 Linux 分支）：
1. `get_configuration_directory_linux` 依赖了 `directories` crate，并执行：
   `directories::ProjectDirs::from("com", "rqbit", "com.rqbit.dht")`。
2. Android 移动沙箱根本不存在 Linux 桌面环境的 `$HOME` 或 `$XDG_CONFIG_HOME` 环境变量与标准目录结构。
3. `directories::ProjectDirs::from` 查询失败并返回 `None`，抛出不可恢复的致命异常：
   `cannot determine project directory for com.rqbit.dht`。
4. 导致引擎在 `Session::new_with_opts` 同步初始化阶段直接报错，返回错误码 `-10`，HTTP 服务启动失败并闪退。

## 决策

为彻底确保 `rqbitx` 在所有平台（尤其是 Android 移动沙箱）上的 100% 启动可靠性，我们对 DHT 持久化实施**完全的路径沙箱隔离**：

1. **沙箱下载目录确定性兜底（Deterministic Sandbox Fallback）**：
   在 `rust/src/lib.rs` 原生层中，当启动配置未显式指定 `dht_persistence` 路径时，引擎自动将持久化路径解析至当前下载目录内部：`<download_dir>/.rqbit/dht.json`。由于 `download_dir` 在启动前已完成创建与写权限校验，因此该路径在宿主进程内绝对可写。
2. **Rust 原生层同步预建父目录**：
   在把配置送入 Session 初始化之前，Rust 运行时会提取父路径并同步执行 `std::fs::create_dir_all`，杜绝文件 IO 创建竞态。
3. **显式自定义路径与禁用选项（Explicit Opt-out & Custom Path）**：
   配置协议（Rust 结构体 `RqbitStartConfig` 与 Dart 的 `RqbitServer.start`）支持可选入参 `dhtPersistencePath` / `dht_persistence`：
   - 传入有效文件路径：精准使用该路径持久化（并自动创建父目录）。
   - 传入空字符串（`""`）：显式将 `persistence` 设为 `None`，以纯内存模式运行 DHT，完全不落盘。
4. **永久禁止隐式系统目录解析**：
   严禁向 `librqbit` 传递 `DhtPersistenceConfig { config_filename: None, .. }`。所有被实例化的 `DhtPersistenceConfig` 必须明确携带 `config_filename: Some(path)`。

## 结果与影响

- **收益（正面）**：
  - 彻底消除了 Android 及沙箱环境下 `cannot determine project directory for com.rqbit.dht` 启动崩溃问题。
  - DHT 路由表在应用重启后能够快速热恢复，提升冷启动后的 Peer 寻径效率。
  - 调用方拥有完全的缓存路径控制权，亦可零成本选择纯内存模式。
- **代价（负面）**：
  - 默认情况下会在用户的 `downloadDir` 下产生 `.rqbit/` 隐藏配置文件夹；若业务层有洁癖，可通过参数显式指定临时缓存目录路径。
