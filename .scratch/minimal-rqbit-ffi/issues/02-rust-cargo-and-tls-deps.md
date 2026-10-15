# 02: Rust Cargo and TLS Dependencies

Status: claimed
Type: research

## Question
编译纯净的 `librqbit` HTTP 服务需要哪些最小 Cargo 依赖配置？如何配置纯 Rust WebPKI 证书以彻底免除 Android/iOS 原生依赖？

### 待调研点
- `librqbit` 的最小 feature 裁剪（只开启 `http-api`，关闭非必要功能）
- `webpki-roots` 与 `rustls` 配合方案，避免引入 `rustls-platform-verifier` 带来的 JNI/Android SDK 链接要求
- 针对 Android NDK、iOS 及各 Desktop 平台的 Rust target 编译兼容性
