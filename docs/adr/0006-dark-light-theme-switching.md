# 0006. 纯平 Bento 体系下的深浅主题 (Dark/Light Mode) 原生主题适配

- **状态**: 已接受 (accepted)
- **日期**: 2026-10-15
- **关联文档**: [ADR-0002 Bento Grid 纯平无边框 UI 设计系统](0002-bento-grid-borderless-ui-design-system.md), [ADR-0004 MediaKit 种子流式视频播放与底部模态](0004-media-kit-torrent-video-streaming.md), [PRD-0001 种子流媒体播放交互规格书](../prd/0001-torrent-streaming-player-ux.md)

## 背景

随着种子解析与在线流媒体视频播放功能的完善，移动端和桌面端用户在暗光环境下的使用场景大幅增加。
在观影与长时间下载监控场景中，需要兼顾系统的自动深浅模式切换与用户的手动切换。

此前曾考虑过自建专有色彩层级类，但违背了奥卡姆剃刀与 YAGNI 原则（多余的代币抽象增加了代码负担，降低了维护性）。Flutter 本身提供的 Material 3 主题系统已经具备完备的深浅色彩语义层级。

## 决策

我们确立了**“依托 Flutter 原生 Theme.of(context) 与 Material 3 ColorScheme”**的极简主题方案：

### 1. 三态主题控制 (ThemeMode Tri-State)
- 支持三种主题模式：
  - **跟随系统 (System)**：默认模式，监听系统亮度（`Brightness.dark` / `Brightness.light`）自适应。
  - **浅色模式 (Light)**：明亮清爽的浅灰底色与白卡片。
  - **深色模式 (Dark)**：深邃沉稳的暗夜黑灰底色与深色卡片。
- **快捷交互**：在顶部 AppBar 右侧放置主题切换按钮（FilledTonal 图标按钮），点击按 `跟随系统 -> 浅色 -> 深色 -> 跟随系统` 循环流转。

### 2. 拥抱原生 Flutter 语义配色 (No Custom BentoColors)
直接利用 Flutter 原生的主题映射：
- **画板底色**：`ThemeData.scaffoldBackgroundColor`
- **Bento 卡片**：`Theme.of(context).cardColor`，纯平圆角 `BorderRadius.circular(22)`，零阴影。
- **内嵌容器（输入框、代码日志、URL 条、指标芯片）**：`Theme.of(context).colorScheme.surfaceContainerHighest`。
- **文字与图标层级**：
  - 主文本：默认文本样式或 `colorScheme.onSurface`
  - 次级与弱化文本：`colorScheme.onSurfaceVariant`
  - 占位提示：`colorScheme.outline`
- **状态徽章**：直接采用语义绿色（`#10B981`）与灰色（`Colors.grey`）带微透明度。

### 3. 流媒体播放器模态底栏沉浸适配
- 底部拉起的 `showModalBottomSheet` 同样直接读取 `Theme.of(context).cardColor` 与 `colorScheme.outlineVariant`，实现无缝同色。

## 结果与影响

- **收益（正面）**：
  - **极致精简**：完全移除 30+ 行冗余的自定义色彩类和跨组件层层传参，代码量精简直观。
  - **遵循官方最佳实践**：所有组件天然响应 Flutter 原生主题体系，兼容未来 Flutter 版本演进。
  - **零维护心智负担**：新增组件直接调用 `Theme.of(context)` 即可，不会再出现“该找哪个代币”的纠结。
