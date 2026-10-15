# 0010. Android 静态 WebPKI 根证书与零 JNI 纯 Rust TLS 校验体系

- **状态**: 已接受 (accepted)
- **日期**: 2026-10-15
- **关联代码**: `rust/rustls-platform-verifier`, `rust/Cargo.toml`
- **关联规范**: [CODING_STANDARDS.md](../../CODING_STANDARDS.md) 规则 8

---

## 1. 背景与痛点 (Context)

在 BitTorrent 客户端中，HTTPS Tracker（如 `https://tracker.example.com/announce`）与 WebTorrent 握手强制依赖 TLS 加密通信。
底层 `librqbit` 依赖 `rustls` 及其生态组件 `rustls-platform-verifier` 来校验证书链。

在 Android 平台上，官方 `rustls-platform-verifier` 默认设计为调用 Java 层的 `TrustManager`（通过 JNI 跨语言调用宿主 JVM 的系统 CA 证书库）。然而在 Flutter Native Assets 架构中：
1. 编译生成的 `librqbitx.so` 是纯粹的 C-ABI 原生动态库；
2. 宿主在加载原生库时，**不会且无法自动向其注入 Android `JavaVM` 指针与上下文**；
3. 一旦 `librqbit` 尝试连接任何 HTTPS Tracker，`rustls-platform-verifier` 在调用 JNI 时会立即因无法获取 `JNIEnv` 抛出严重运行时异常（SIGSEGV 或 Panic），导致 App 闪退。

---

## 2. 决策考量与候选方案 (Decision Drivers)

- **方案 A：宿主 JNI 显式注入**
  - 要求在 Dart 侧启动时通过 Platform Channel 获取 Android Context，调用 JNI 函数传入 C 侧初始化全局 JavaVM。
  - *致命缺陷*：严重破坏跨平台统一生命周期，依赖 Android 专有 Java 代码，无法在 iOS/macOS/Windows/Linux 上复用，且存在生命周期时序竞争。
- **方案 B：本地 Crate Patch + 纯 Rust WebPKI 静态内嵌 (最终采纳)**
  - 利用 Cargo 的 `[patch.crates-io]` 特性，对 `rustls-platform-verifier` 进行本地补丁重定向。
  - 在 `target_os = "android"` 时，彻底掐断对 JNI 的调用，将其路由至纯 Rust 实现的 `others::Verifier`，静态嵌入 Mozilla 官方认证的根证书库（`webpki-root-certs`）。

---

## 3. 具体实现架构 (Implementation)

在 `rust/Cargo.toml` 中配置本地依赖拦截：

```toml
[patch.crates-io]
rustls-platform-verifier = { path = "rustls-platform-verifier" }
```

在 `rust/rustls-platform-verifier/src/lib.rs` 中，抹除 Android 特殊 JNI 分支，将 Android 与其他非 JNI 平台统一归口：

```rust
#[cfg(all(
    any(
        target_os = "android",
        target_os = "windows",
        target_os = "macos",
        target_os = "linux"
    ),
    feature = "webpki-roots"
))]
pub use others::Verifier;
```

---

## 4. 后果与权衡 (Consequences)

### 正向收益 (Positive)
- **零 JNI 零闪退**：彻底杜绝未初始化 JVM 上下文导致的进程级崩溃，跨平台 C-ABI 保持极致纯粹。
- **开箱即用，极速握手**：纯 Rust 内存中完成根证书解析与校验，无 JNI 上下文切换开销。
- **确定性与安全性**：内嵌权威 Mozilla WebPKI 证书链，不受特定厂商移动系统魔改或老化系统根证书过期的负面影响。

### 权衡与取舍 (Tradeoffs)
- **私有 CA 限制**：移动设备用户自行在系统设置中安装的企业私有根证书或 Charles/Mitmproxy 代理抓包证书，默认不会被该纯 Rust 校验器信任（符合标准 BT Tracker 公网通讯场景要求）。
