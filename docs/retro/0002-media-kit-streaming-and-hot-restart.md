# Retro 0002: media-kit 边下边播流媒体与 Flutter Hot Restart 守护常驻复盘

> **审查阶段**：流媒体播放器接入与开发体验调优（对应 PRD-0001 与 ADR-0004 ~ ADR-0006）  
> **复盘目标**：审视第三方依赖引入摩擦、生命周期设计短板与 URI 拼接防线。

---

## 一、会话摩擦点与踩坑事实回顾 (What Went Wrong)

1. **摩擦点 1：`media_kit` 官方版本与 Dart Monorepo 依赖冲突**
   - **现象**：引入官方 pub.dev 版本的 `media_kit` 后，触发了 `dependency_overrides` 解析冲突，最新 Flutter 引擎报错符号未决。
   - **根本原因**：Flutter 原生视频与 Native Assets 仍处于快速演化期，官方 pub 包跟不上最新 SDK。最终被迫切换到 `Predidit/media-kit` git HEAD 仓库，并使用覆盖机制才得以解决。

2. **摩擦点 2：Flutter Hot Restart 导致 rqbit 守护进程被迫中断或失联**
   - **现象**：开发人员在 VS Code / Android Studio 中点击 Hot Restart 时，Dart VM 内存与 Widget 树完全重置；原代码在 `dispose()` 中盲目调用了 `_server?.stop()`，导致后台正在跑的 BitTorrent 下载被意外掐断；或者重载后 Dart 重新 `start` 试图重复绑定已被占用的端口。
   - **根本原因**：未将“开发期代码热重载”与“原生底层守护进程生命周期”正交解耦。原生 Tokio 线程跑在操作系统底层，其生命周期天然独立于 Dart VM 重启。

3. **摩擦点 3：流直链拼接由于缺少斜杠抛出 `FormatException`**
   - **现象**：点击播放时，视频播放器报 URI 解析异常，偶发出现 404 找不到切片。
   - **根本原因**：早期代码采用简单的字符串插值拼接（`$baseUrl/torrents/...`），当 `baseUrl` 尾部带斜杠或不带斜杠时未做严谨规范化。

---

## 二、环境改进候选方案 (Environment Improvements)

### 1. 代码审查准则 (Reviewer Coding Standards)
- **URL/URI 构造铁律**（沉淀入 `CODING_STANDARDS.md`）：
  - 严禁在生产代码中使用手动字符串插值拼接 API 或流媒体 URL；
  - 必须强制使用 `Uri.resolve()` 或已封装好的客户端规范方法进行路径派生，杜绝双斜杠或丢失斜杠引起的 `FormatException`。
- **守护进程常驻设计准则**：
  - 底层原生后台进程必须始终提供只读无副作用的“探活与端口发现”接口（如 `rqbit_get_port()`）；
  - Dart 层必须始终提供 `startOrAttach()` 自愈方法，保证 Hot Restart 期间下载不中断。

### 2. 自动化测试守护 (Automated Checks)
- **发现**：之前未对热重启状态自愈编写测试，全靠真机手工复盘。
- **改进措施**：
  - 在 `test/rqbitx_test.dart` 中建立自动化生命周期连续性测试（验证 `start` 后通过 `current()` 获取相同端口，并能正常完成 HTTP 请求）。
