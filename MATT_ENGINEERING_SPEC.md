# Matt Pocock's Agentic 软件工程规范全景指南 (Matt's Skills Spec)

> 本文档完整系统地提炼并规范化了 Matt Pocock 设计的 AI Agent 驱动软件工程工作流体系。
> 涵盖绿地全新项目（Greenfield Project）、日常缺陷修复（Bug Fixing）、新功能演进（Feature Proposal）的全生命周期标准操作规程（SOP）。

---

## 目录

1. [核心设计哲学与四大铁律](#一核心设计哲学与四大铁律)
2. [项目基础底座准备 (Preconditions)](#二项目基础底座准备-preconditions)
3. [从零启动全新项目全流程 (Greenfield Project)](#三从零启动全新项目全流程-greenfield-project)
   - 3.1 迷雾开局流：`/wayfinder`（大型未知项目）
   - 3.2 确定性主干流：Main Flow（`/grill-with-docs` → `/to-spec` → `/to-tickets`）
   - 3.3 原型分支旁路：`/handoff` ⇄ `/prototype`
   - 3.4 模块实施与并行构建：`/implement` / `/implement-spec`
   - 3.5 双轴质量审查与交付：`/code-review` → `/pr`
   - 3.6 环境复盘闭环：`/retro`
4. [日常缺陷诊断与修复规范 (Bug Fixing Flow)](#四日常缺陷诊断与修复规范-bug-fixing-flow)
   - 4.1 缺陷分拣状态机：`/triage`
   - 4.2 严格诊断三步法：`/diagnosing-bugs`
   - 4.3 缺陷复盘与架构自愈：`/retro` → `/improve-codebase-architecture`
5. [新功能提案与演进规范 (Feature Proposal Flow)](#五新功能提案与演进规范-feature-proposal-flow)
   - 5.1 外部输入：`/triage` 与 `/to-questionnaire`
   - 5.2 内部驱动：`/improve-codebase-architecture` 与深模块设计
   - 5.3 汇流并入主流程
6. [支撑体系与底层词汇层 (Underlying Foundations)](#六支撑体系与底层词汇层-underlying-foundations)
   - 6.1 阶段边界跃迁模型 (Phase Boundaries)
   - 6.2 领域语言规范：`/domain-modeling`
   - 6.3 深度模块设计：`/codebase-design`
   - 6.4 人机协同隔离向导：`/wizard`
7. [反模式警示录与速查矩阵](#七反模式警示录与速查矩阵)

---

## 一、核心设计哲学与四大铁律

Matt 规范的底层支柱是将人类开发者的**高阶决策与审美**同 AI Agent 的**极致代码吞吐与执行力**分离解耦，恪守以下四大工程铁律：

```text
┌──────────────────────────────────────────────────────────┐
│                   Matt 体系四大工程铁律                  │
├─────────────────────┬────────────────────────────────────┤
│ 1. 上下文卫生法则   │ 规约期连贯统一，实现期单票重置上下文 │
│    (Context Hygiene)│ 严守 ~150k Smart Zone 高智力区间   │
├─────────────────────┼────────────────────────────────────┤
│ 2. 曳光弹垂直切片   │ 严禁纯横向切片，每张票必须打穿全链路│
│    (Tracer Bullets) │ 显式声明依赖拓扑阻塞边 (Blockers)   │
├─────────────────────┼────────────────────────────────────┤
│ 3. 反馈环第一原则   │ 无红灯不改码，无测试不实现         │
│    (Feedback Loop)  │ 倾注最大心力构建一键失败重现命令   │
├─────────────────────┼────────────────────────────────────┤
│ 4. 面向环境的复盘   │ 不做无用口头训诫，将失误转化为机器 │
│    (Retro on Env)   │ 确定性规则 (CI / Lint / Pointers)  │
└─────────────────────┴────────────────────────────────────┘
```

1. **事实是 Agent 的职责，决策是人类的特权**：Agent 负责穷尽细节、收集一手证据、编写自动化验证；关键业务规则、权衡取舍、单向门决策必须交由人类敲定。
2. **上下文卫生（Context Hygiene）**：严禁在一个无限膨胀的单一会话窗口中从头干到尾。规约讨论完成后必须执行 `/clear`；每一个子任务 Ticket 作为全新上下文启动。
3. **高位单接缝设计（Highest Single Seam）**：测试接缝越少越好，理想情况下为一个高位接缝（如业务 API 入口或 CLI 调度器），避免脆弱琐碎的低级 Mock 测试。

---

## 二、项目基础底座准备 (Preconditions)

启动任何开发工作前，工作区必须完成规范化基建：

```bash
# 运行前置初始化流程
/setup-matt-pocock-skills
```

### 1. 核心知识库与规范文件
- **`AGENTS.md` / `CLAUDE.md`**：定义 Agent 的行为准则、环境约束与工具调用规则。
- **`GLOSSARY.md`**：记录项目的统一定义领域语言（Ubiquitous Language），严禁同一概念多个称谓或单个词汇超载（Overloaded Words）。
- **`.agents/adr/`**：架构决策记录（Architecture Decision Records），记录“为什么选 X 而弃用 Y”的不可逆决策。
- **`.out-of-scope/`**：明确排除在外的需求与防发散知识库。

### 2. 任务跟踪系统 (Issue Tracker)
规范支持本地文件跟踪器或云端平台（GitHub Issues / Linear）：
- **本地跟踪器结构**：`.scratch/<feature>/issues/<id>.md`
- **Triage 标签体系**：
  - 类型：`bug`、`enhancement`
  - 状态：`needs-triage`、`needs-info`、`ready-for-agent`、`ready-for-human`、`wontfix`

---

## 三、从零启动全新项目全流程 (Greenfield Project)

```text
                            从零启动新项目
                                  │
                   ┌──────────────┴──────────────┐
                   ▼                             ▼
           [范围宏大/迷雾重重]            [范围明确/中小型]
                   │                             │
             /wayfinder                          │
     (绘制决策地图, 逐个攻克决策)                  │
                   │                             │
                   └──────────────┬──────────────┘
                                  ▼
                          /grill-with-docs
                   (高强度审讯需求, 沉淀术语/ADR)
                                  │
                        [是否有需要运行的原型?]
                        ├── 是 ──► /handoff ──► /prototype ──► /handoff ──┐
                        └── 否 ───────────────────────────────────────────┤
                                                                          ▼
                                                                       /to-spec
                                                               (高保真提炼规格书, 确定测试接缝)
                                                                          │
                                                                          ▼
                                                                     /to-tickets
                                                               (拆解自包含曳光弹切片与阻塞依赖)
                                                                          │
                                ┌─────────────────────────────────────────┴─────────────────────────────────────────┐
                                ▼                                                                                   ▼
                       [单票依次推进模式]                                                                  [全图多 Agent 并发模式]
                                │                                                                                   │
                             /clear                                                                         /implement-spec
                                │                                                                      (读取任务图, 并行推进 Frontier,
                                ▼                                                                        统一汇入 integration branch)
                           /implement                                                                               │
                     (严格 TDD 驱动实现)                                                                            │
                                │                                                                                   │
                                ▼                                                                                   │
                          /code-review                                                                              ▼
                      (Standards + Spec 双轴审查)                                                             /code-review
                                │                                                                                   │
                                └─────────────────────────────────────────┬─────────────────────────────────────────┘
                                                                          ▼
                                                                         /pr
                                                            (生成结构化 PR: 演示+证据+单向门)
                                                                          │
                                                                          ▼
                                                                        /retro
                                                            (反思会话摩擦, 固化环境与自动化规则)
```

### 3.1 迷雾开局流：`/wayfinder`（大型未知项目）
- **适用场景**：单次会话装不下、方向充满迷雾、架构路径不明确的从零起步大型工程。
- **核心动作**：
  1. **Plan, don't do**：严禁直接写功能代码。
  2. 建立由 **决策票（Decision Tickets）** 构成的任务依赖图（每一张票解决一个核心架构未知数）。
  3. 逐步推进前沿（Frontier），每攻克一张决策票，将决议固化为 ADR。
  4. 迷雾退散时执行**坍缩交付（Collapse and Handoff）**，平滑转入 `/to-spec`。

### 3.2 确定性主干流：Main Flow

#### 步骤 1：深度需求审讯（`/grill-with-docs`）
- 采用苏格拉底式高强度提问，逼问出所有隐性假设、边界条件、非功能要求。
- 过程产物实时落地：
  - 更新 `GLOSSARY.md` 固化专业名词。
  - 产出关键权衡的架构决策（ADR）。

#### 步骤 2：原型旁路验证（`/handoff` ⇄ `/prototype`）
- **触发条件**：UI 交互感、状态机合法性、复杂算法等纯凭语言讨论无法定论的问题。
- **操作规范**：
  1. 调用 `/handoff` 将当前思考与上下文冻结为独立文档。
  2. 新开隔离会话运行 `/prototype`，编写**运行即可丢弃**的原型代码。
  3. 产出的原型代码保存在 `prototype/<name>` 分支作为永久“一手参考源（Primary Source）”。
  4. 再次调用 `/handoff` 将原型结论与参数回填至主分支会话。

#### 步骤 3：规格书生成（`/to-spec`）
- **铁律**：此时**不再向用户提问**，纯粹将前期已收敛的共识进行高保真结构化提炼。
- **测试接缝（Seam）设计**：
  - 寻找或定义最高层的单一测试接缝。
  - 接缝必须具备低磨损、抗重构特性（如调度核心层输入输出）。
- 规格书包含：Problem Statement、Solution、User Stories、Seams、Out of Scope。

#### 步骤 4：曳光弹垂直切片（`/to-tickets`）
- 将 Spec 拆解为一组自包含的 Tickets。
- **垂直切片铁律**：严禁水平分工（禁止单独切“只建数据库表”、“只写接口”、“只画页面”）。每个切片必须纵向打穿数据、逻辑、交互与测试全层级。
- **依赖拓扑**：每张票必须显式声明其前置阻塞项（`Blocked by: #1, #2`），形成清晰的有向无环图（DAG）。

### 3.3 实施构建与质量闭环

#### 上下文清空（Context Hygiene Checkpoint）
- 规划完成（`/to-tickets`）后，**必须执行 `/clear` 清空会话**！
- 彻底告别疲劳且膨胀的上下文历史，防止模型跌出智能区（Smart Zone）。

#### 步骤 5：隔离实施（`/implement` 或 `/implement-spec`）
- **单票人工推进（`/implement`）**：单票加载上下文，专注攻克一张 Ticket。
- **全图并行编排（`/implement-spec`）**：由主控 Agent 读取 Ticket 依赖图，自动为 Frontier（就绪节点）派生 Implementer 子 Agent 并发编写，最后统一合入 `integration` 分支。
- **TDD 实施铁律**：
  1. **Red**：基于接缝写出高表达力的失败测试。
  2. **Green**：编写最克制的精炼代码使测试通过。
  3. **Refactor**：对照 `/codebase-design` 重构，打造具备深度的紧凑接口。

#### 步骤 6：双轴审查与交付（`/code-review` → `/pr`）
- **`/code-review` 双轴并行审查**：
  - **Standards 轴**：代码是否符合项目规范、安全准则与性能要求。
  - **Spec 轴**：实现是否百分之百忠实于 Ticket 规约，有无暗中删减需求或过度设计（Gold-plating）。
- **`/pr` 自动化发布**：
  - 自动渲染 PR 描述体：包含最小直观验证界面（Visuals/GIF）、前后对比证据（Before/After Evidence）、单向门与双向门决策说明（One-way / Two-way doors）。

#### 步骤 7：环境进化复盘（`/retro`）
- 交付完成后在原会话中就地运行。
- **核心审视点在于“开发环境”，而非指责代码**：
  - **Navigation**：Agent 搜寻代码时是否卡顿？需要补充哪些文件索引（Navigation Pointers）？
  - **Automated Checks**：Agent 犯的错误能否被 Lint、TypeScript 强类型或 Pre-commit Hook 机械化拦截？
  - **Steering**：哪些潜规则需要补充进 `AGENTS.md` 或 Coding Standards？

---

## 四、日常缺陷诊断与修复规范 (Bug Fixing Flow)

面对任何崩溃、异常或性能衰退，严禁直接让 Agent 猜测性改代码。严格遵循三阶段诊断闭环：

```text
[原始 Bug 汇报 / 堆积 Issue]
          │
          ▼
       /triage
 (状态机流转：定级分类、补充信息、生成自包含 Agent-Ready Brief)
          │
          ▼
   /diagnosing-bugs
 ┌────────────────────────────────────────────────────────────┐
 │ Phase 1: 建立紧密反馈环 (Tight Feedback Loop)              │
 │          必须找到一条单命令/测试，能针对该 Bug 稳定报红!    │
 ├────────────────────────────────────────────────────────────┤
 │ Phase 2: 二分追踪根因 (Bisect & Trace)                     │
 │          依托红灯测试，通过 Git Bisect / 最小插桩定位根因  │
 ├────────────────────────────────────────────────────────────┤
 │ Phase 3: 回归测试与最小修复 (Regression Test & Fix)         │
 │          固化红灯为回归用例，以最小代码变更使其变绿        │
 └────────────────────────────────────────────────────────────┘
          │
          ▼
        /retro
 (反思防线漏洞：为何 CI 没拦住？若接缝不良则触发架构深化)
          │ (若接缝腐化)
          ▼
 /improve-codebase-architecture
```

### 4.1 缺陷分拣状态机（`/triage`）
- 针对他人提交的原始 Issue 进行分类治理：
  - 补齐复现步骤（`needs-info`）。
  - 若超出范围则拒绝并沉淀至 `.out-of-scope/`（`wontfix`）。
  - 提炼自包含的执行简报（Agent Brief），打上 `ready-for-agent` 标签后推入实施。

### 4.2 严格诊断三步法（`/diagnosing-bugs`）

#### 铁律：无 Tight Feedback Loop，绝不盲目改动代码！
1. **Phase 1: 构造紧密反馈循环（Build a Feedback Loop）**
   - 投入不成比例的最大心力，必须构建出**一条命令就能百分之百稳定触发该 Bug 报红**的用例。
   - 构造优先级：
     1. 最高接缝处的单元/集成自动化测试用例（Failing Test）。
     2. 针对开发服务器的单条 Curl / HTTP 脚本。
     3. 最小复现 CLI 命令。
2. **Phase 2: 追踪与定位根因（Bisect & Isolate）**
   - 既然手中已有稳定红灯测试，定位工作变为纯机械化流程。
   - 利用 `git bisect` 找到引入故障的始作俑提交，或沿接缝进行最小化观察插桩。
3. **Phase 3: 回归测试与精准变绿（Regression Test & Fix）**
   - 将 Phase 1 构建的红灯用例正式转为代码库中的永久**回归测试（Regression Test）**。
   - 进行最少必要的代码修改，让测试刚好由红变绿。

### 4.3 缺陷复盘与架构自愈（`/retro`）
- 修复完成后在当前会话运行 `/retro`：
  - 追问：“为什么现有的自动化测试网没能在合并前拦截该 Bug？”
  - 如果结论是“该模块没有暴露干净的接缝，导致极难编写轻量隔离测试”，则说明代码产生架构腐化，立即标记为技术债，调度 **`/improve-codebase-architecture`** 安排深模块重构。

---

## 五、新功能提案与演进规范 (Feature Proposal Flow)

新功能绝非临时插队或杂乱演化，所有提案均被标准化接入主管道：

```text
                    新功能/演进输入源
                           │
            ┌──────────────┴──────────────┐
            ▼                             ▼
       [外部需求/提议]               [内部架构洞察]
            │                             │
         /triage            /improve-codebase-architecture
  (分拣定级 enhancement)      (扫描深模块机会 Deepening Ops)
            │                             │
    [信息不全/有代沟?]                    │
   /to-questionnaire                      │
  (生成反向问卷填平信息)                  │
            │                             │
            └──────────────┬──────────────┘
                           ▼
                    /grill-with-docs
                 (对齐术语/更新 ADR/入轨)
                           │
                           ▼
                  并入 Main Flow 闭环
       (Spec → Tickets → TDD → Review → Retro)
```

### 5.1 外部输入管道
1. **分拣与定级（`/triage`）**：为 Issue 打上 `enhancement` 标签。
2. **信息反向调研（`/to-questionnaire`）**：
   - 当需求来自外部人员、业务方或客户，且关键上下文缺失时，不直接空想。
   - 自动生成结构化的**反向调查问卷**发放给提出人，明确业务边界后再推进。

### 5.2 内部架构演进管道（`/improve-codebase-architecture`）
- 在日常维护间隙主动运行。
- 扫描代码库中的“浅模块（Shallow Modules）”——即接口繁琐笨重、内部逻辑脆弱、对外部产生大量泄漏抽象的模块。
- 挖掘**深化机会（Deepening Opportunities）**，基于 `/codebase-design` 设计高内聚低耦合的深度接口，转化为具体的架构升级提案。

### 5.3 汇流并入主干
一旦提案明确，无论来自外部还是内部，统一作为 Idea 输入并入主流程 **Main Flow**：
`/grill-with-docs` → `/to-spec` → `/to-tickets` → `/implement` → `/code-review` → `/pr` → `/retro`。

---

## 六、支撑体系与底层词汇层 (Underlying Foundations)

### 6.1 阶段边界跃迁模型 (Phase Boundaries)
在两个工作阶段交汇的边界点，遵循明确的决策树（Phase Transition Tree）：

```text
                    阶段交界点 (Phase Boundary)
                                 │
                   ┌─────────────┴─────────────┐
                   ▼                           ▼
        [当前上下文对后续无价值]       [需要换设备/跨仓库/协作]
                   │                           │
                /clear                      /handoff
                                               │
                   ┌───────────────────────────┘
                   ▼
        [需要并行派生子任务] ──► Subagent
                   │
                   ▼
        [接近 150k Smart Zone 临界?]
        ├── 是 ──► /compact (压缩摘要后开启新会话)
        └── 否 ──► Continue (原地继续推进)
```

### 6.2 领域语言规范：`/domain-modeling`
- **唯一真理来源**：`GLOSSARY.md`。
- 严禁模糊与多义性：如“Account”究竟代表登录凭证、计费主体还是组织租户？必须在领域模型中彻底拆分明确。

### 6.3 深度模块设计：`/codebase-design`
- **Depth（深度）**：追求极致的深模块——对外接口极其小巧易用，内部隐藏极为庞大复杂的逻辑与状态管理。
- **Seam（接缝）**：在系统的自然连接处建立接缝（如网络层、存储层接口），使测试代码能无痛切入而无需破坏生产实现。
- **Leverage（杠杆）**：给调用方带来最大的功能杠杆，减少调用方的样板准备代码。

### 6.4 人机协作向导：`/wizard`
- **专注人类专属动作**：当任务遇到第三方云平台控制台点选、OAuth 凭证申请、生产数据库迁移等必须人类实体身份介入的卡点时自动唤起。
- 自动生成交互式 Bash 交互向导脚本，引导人类完成并在本端捕获环境变量写入 `.env` 或 GitHub Secrets，杜绝人类反复手工配置的遗漏。

---

## 七、反模式警示录与速查矩阵

### 1. 常见反模式清单 (Anti-Patterns to Avoid)

| 禁忌反模式 | 现象表现 | 规范化正解 |
| :--- | :--- | :--- |
| **单会话马拉松 (Context Blob)** | 从头脑风暴到写完几千行代码都在一个窗口，模型输出质量暴跌 | 规划后立即 `/clear`，分票独立启动，守住 Smart Zone |
| **水平切片 (Horizontal Slicing)** | “我先建完所有表，再写所有 API，最后画页面” | 必须使用曳光弹垂直切片（Tracer Bullets），一次打通端到端 |
| **脑补式修 Bug (Guessing Debug)** | 还没复现错误，直接看代码猜原因并上手修改 | 必须在 `/diagnosing-bugs` Phase 1 建立稳定红灯命令后才能动生产代码 |
| **自言自语式复盘 (Empty Retro)** | 复盘时只是在会话里互相道辛苦，没有改动任何配置文件 | 复盘产出必须是真实的 Lint 规则、CI 校验、Navigation 指针或 `AGENTS.md` |
| **浅模块泛滥 (Shallow Interfaces)** | 导出一大堆细碎的 Helper 函数，调用方必须按顺序调 5 个函数才能干成一件事 | 重构为深模块，对外只提供单一清晰的高层接口方法 |

---

### 2. 常用命令速查矩阵 (Command Quick Reference)

| 阶段 | 触发指令 / 技能 | 核心产出物 / 目标 |
| :--- | :--- | :--- |
| **前置基建** | `/setup-matt-pocock-skills` | 初始化 Tracker、Triage 标签、`AGENTS.md`、`GLOSSARY.md` |
| **迷雾开荒** | `/wayfinder` | 依赖决策图、ADR 集合，清退大项目迷雾 |
| **需求审讯** | `/grill-with-docs` | 消除隐性假设，更新 `GLOSSARY.md` 与 ADR |
| **原型试错** | `/handoff` ⇄ `/prototype` | 在独立分支验证 UI/状态机，形成一手代码证据 |
| **规格收敛** | `/to-spec` | 结构化 Spec、单一最高测试接缝定义 |
| **任务切片** | `/to-tickets` | 自包含曳光弹切片，显式声明阻塞依赖拓扑 |
| **代码构建** | `/implement` / `/implement-spec` | 严格 TDD（红→绿→重构），打造深模块 |
| **质量审查** | `/code-review` | Standards 与 Spec 双轴并行子 Agent 审查 |
| **发布交付** | `/pr` | 高质量 PR：前后直观证据、单向门/双向门考量 |
| **环境进化** | `/retro` | 改进 Agent 运行环境（Lint、CI、指针、规范） |
| **缺陷排查** | `/diagnosing-bugs` | 紧密反馈环单命令、二分定位、回归测试 |
| **缺陷分拣** | `/triage` | 状态机分拣、产出自包含 Agent Brief |
| **架构重构** | `/improve-codebase-architecture` | 扫描浅模块，提炼深模块演进机会 |
| **人工卡点** | `/wizard` | 生成人机交互脚本，处理凭证与控制台迁移 |
