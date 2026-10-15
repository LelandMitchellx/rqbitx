# CODING_STANDARDS.md

> **适用范围**：Reviewer Agent 代码审查（Standards 轴）及人类开发者协同参考。  
> **核心原则**：机械性校验（如格式化、语法分析）由 linter/CI 拦截；本文档专门沉淀无法被编译器机械拦截的**高阶架构决策、跨平台边界与真机环境判断准则**。

---

## 1. 跨平台路径与环境变量隔离 (Cross-Platform Path Isolation)
- **准则**：严禁在 Rust 库代码中假设存在 Linux 桌面规范环境变量（如 `$HOME`、`$XDG_CONFIG_HOME`、`$TMPDIR`）。
- **审查要点**：
  - 移动端（Android / iOS）天然不存在标准桌面 `$HOME`。所有涉及文件读写、缓存目录、数据库、DHT 持久化的路径，必须强制由 Dart 宿主层通过 `path_provider` 注入绝对路径；
  - 若提供默认路径，必须显式兜底为由 Dart 传入的 `downloadDir` 子路径（如 `<downloadDir>/.rqbit/dht.json`），且在 Rust 侧写入前必须预先递归创建父目录 (`fs::create_dir_all`)；
  - 详见 [ADR-0003](docs/adr/0003-dht-persistence-path-isolation.md)。

---

## 2. C-ABI 极简高位接缝与绝对 Panic 隔离 (FFI Panic Safety)
- **准则**：保持最窄 C-ABI 接口，严禁 Rust panic 击穿进程。
- **审查要点**：
  - Rust 导出函数只允许覆盖守护进程生命周期管控（`rqbit_start`, `rqbit_stop`, `rqbit_is_running`, `rqbit_get_port`, `rqbit_last_error`），所有业务逻辑必须走 HTTP REST API；
  - 每一个导出的 `extern "C"` 函数体内部必须全部由 `std::panic::catch_unwind` 包裹，绝不允许 panic 穿透 C-ABI 边界导致 Flutter 宿主进程闪退；
  - 字符串入参必须进行空指针与 UTF-8 校验，出参必须提供配套的释放函数（`rqbit_free_str`）。

---

## 3. URL/URI 构造防线 (Safe URI Construction)
- **准则**：严禁在生产代码中使用裸字符串插值拼接 API 或流媒体 URL。
- **审查要点**：
  - 涉及网络请求或视频流播放地址的组装，必须统一使用 `Uri.resolve()` 或 SDK 内置安全方法；
  - 任何表示 Base URL 的 `Uri` 或字符串，末尾必须保证斜杠语义清晰，杜绝丢失斜杠或双斜杠造成的 `FormatException` 或 404 错误。

---

## 4. 单实例深模块与资源自动级联释放 (Unified Instance & Automatic Cleanup)
- **准则**：提供极致调用杠杆，避免让消费方同时维护多个分离句柄。
- **审查要点**：
  - `RqbitServer` 必须直接继承自 `RqbitClient`，消费层只持有一个 `server` 实例即可同时管理后台守护进程与调用全部 1:1 REST API；
  - 生命周期联动：调用 `server.stop()` 时，内部必须自动联动调用 `dio.close(force: true)` 彻底释放底层的 HTTP 连接池，严禁要求调用方手动双重释放。
  - 详见 [ADR-0009](docs/adr/0009-server-inherits-client-unified-instance.md)。

---

## 5. 1:1 Rust 领域模型忠实性与空容错 (Model Fidelity & Null Safety)
- **准则**：领域模型必须 1:1 镜像官方 `librqbit` 源码定义，杜绝黑盒松散解析。
- **审查要点**：
  - 所有 DTO 属性名、嵌套结构、可选类型（`Option<T>` 对应 Dart 的 `T?`）必须与 Rust 结构体完全一致；
  - 反序列化严禁裸类型强转（如 `json['key'] as int`），必须使用安全的解析或带有默认值的工厂方法；
  - 新增任何模型必须配套单元反序列化契约测试（`test/models_test.dart`）。

---

## 6. 守护常驻与 Hot Restart 自愈不变量 (Hot Restart Persistence Invariant)
- **准则**：保护开发期下载体验连续性。
- **审查要点**：
  - 严禁在 Widget 的 `dispose()` 方法中直接调用 `server.stop()`；
  - 底层原生后台进程必须导出无副作用的端口探针；Dart 必须提供 `RqbitServer.startOrAttach()`，保证 Flutter 执行热重启时能够毫秒级重新附着到活跃的后台服务上；
  - 详见 [ADR-0005](docs/adr/0005-hot-restart-daemon-persistence.md)。

---

## 7. 生产清单与网络安全基线 (Security & Manifest Baseline)
- **准则**：投产前必须核验移动平台权限与网络暴露面。
- **审查要点**：
  - Android 清单文件（`AndroidManifest.xml`）必须显式声明 `INTERNET` 与 `ACCESS_NETWORK_STATE`；
  - 本地监听的 HTTP 服务需考虑防止第三方网页发起的 CSRF 恶意删除，投产前应实现临时随机 Token 鉴权机制。

---

## 8. Android 平台 TLS 零 JNI 与 WebPKI 纯 Rust 闭环 (Pure-Rust WebPKI TLS)
- **准则**：严禁在 Native Assets C-ABI 动态库中隐式依赖宿主虚拟机（JNI/JVM）进行平台证书链校验。
- **审查要点**：
  - Android 移动环境下运行的 Rust 原生库（`librqbitx.so`）必须通过静态嵌入 Mozilla WebPKI 根证书（`webpki-root-certs`）进行 TLS 校验，杜绝因未初始化 JNI 上下文调用 Java `TrustManager` 导致的致命运行时 Panic；
  - Cargo 依赖中必须使用 `[patch.crates-io]` 本地补丁接管 `rustls-platform-verifier`，并将 Android target 强制重定向至 WebPKI 纯 Rust 分支；
  - 详见 [ADR-0010](docs/adr/0010-android-webpki-pure-rust-tls-verifier.md)。

---

## 9. 变更必留痕铁律 (Mandatory Changelog Traceability)
- **准则**：杜绝黑盒变更，每一次改动都必须可追溯。
- **审查要点**：
  - 任何新增需求提案、Bug 修复或重大架构重构，在提交代码的同时**必须同步更新根目录 `CHANGELOG.md`**；
  - 记录必须包含：阶段编号、变更类型、产生背景（Why）、具体修改内容（What）、以及关联的 ADR/PRD/Retro/Commit。
