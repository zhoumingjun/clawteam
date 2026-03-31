## Context

Claw Team 使用 OpenClaw 平台管理 6 个 AI Agent（manager, arch, dev, qa, sre, research）+ 1 个 default fallback。每个 Agent 的 workspace 在 `config/agents/<role>/` 下，包含 7 个 Markdown 模板文件。

当前这些文件是项目早期编写的，内容虽然丰富但与 OpenClaw 官方模板规范严重不匹配——内容放在了错误的文件里。OpenClaw 运行时按照固定语义加载这些文件（SOUL.md 在每次 session 启动时读取定义身份，MEMORY.md 仅在 main session 加载等），文件内容不对齐会导致 Agent 行为异常。

约束：
- 7 个 Agent 目录 × 8 个文件（含新增 BOOTSTRAP.md）= 63 个文件
- 保持中文风格，但融入 OpenClaw 的"有人格"写法
- 不能丢失当前有价值的业务内容（角色职责、协作规则、任务卡片模板、交付物标准等）

## Goals / Non-Goals

**Goals:**
- 每个模板文件的结构和内容严格对齐 OpenClaw 官方定义
- 有价值的业务内容迁移到正确的文件位置
- 每个 Agent 有独特的人格和身份感（不是千篇一律的 Job Description）
- default/ 成为真正的通用 fallback 模板，不再是 manager 的拷贝

**Non-Goals:**
- 不修改 OpenClaw 运行时代码或 Docker 配置
- 不修改 `containers/`、`devops/`、`Makefile` 等文件
- 不重新设计 Agent 角色或协作流程（保留现有 6 角色体系）
- 不引入新的模板文件类型（仅使用 OpenClaw 官方定义的文件）

## Decisions

### D1: 内容迁移策略 — "正确的内容放到正确的文件"

当前内容迁移映射：

| 当前位置 | 内容 | 迁移到 |
|----------|------|--------|
| IDENTITY.md → Matrix ID、安全边界 | 身份+安全 | SOUL.md 的 Boundaries 节 |
| AGENTS.md → 协作规则、交付物标准 | 协作 | AGENTS.md 保留，补充官方必需节 |
| TOOLS.md → 心跳检查项 | 心跳 | HEARTBEAT.md |
| TOOLS.md → 能力列表 | 参考 | AGENTS.md 的 Tools 节（简要引用）|
| MEMORY.md → 存储配置 | 配置 | 删除（不需要，OpenClaw 自动管理存储路径）|

**理由**: OpenClaw 运行时对每个文件有固定的加载时机和语义预期，必须对齐才能正常工作。

### D2: SOUL.md 写法 — 人格驱动而非职责驱动

每个 Agent 的 SOUL.md 采用 OpenClaw 官方的 5 段结构：
1. **Core Truths** — 改写为该角色视角的 5 条人格信念（不是通用的 5 条）
2. **Boundaries** — 融入当前 IDENTITY.md 的安全边界 + Matrix ID
3. **Vibe** — 一句话描述风格（如 arch: "严谨但不刻板，数据说话"）
4. **Role Context** — 保留角色职责的精华（2-3 句话，不是完整 JD）
5. **Continuity** — 标准的 session 持续性说明

**理由**: OpenClaw 的 SOUL.md 设计理念是"你不是聊天机器人，你正在成为某个人"。纯职责列表无法建立 Agent 的个性。

### D3: AGENTS.md 结构 — 官方必需节 + 业务扩展

AGENTS.md 采用混合结构：
1. 官方必需节（Session Startup / Memory / Red Lines / Group Chat / Heartbeat / Tools）
2. 业务扩展节（Team Protocol / Task Card / Deliverables）— 当前有价值的协作规则迁入此处

其中 Group Chat 节特别重要——当前缺失，但 Claw Team 所有通信都在 Matrix 群组房间内进行。需要针对 Matrix 团队房的场景定制 Group Chat 行为规则。

**替代方案**: 完全按官方模板，不保留业务扩展。**否决理由**: 协作规则和交付物标准是 Claw Team 的核心价值，去掉会降低 Agent 的工作质量。

### D4: default/ 目录定位 — 通用 fallback

default/ 不再是 manager 的拷贝，而是一个最小化的通用模板：
- SOUL.md: 通用 AI 助手身份（无特定角色）
- AGENTS.md: 最小操作手册（仅官方必需节）
- 其他文件: 最小化种子内容

**理由**: OpenClaw 的 default workspace 是 Gateway 启动时的 main agent 使用的，应该是一个协调者角色而非特定业务角色。

### D5: MEMORY.md 初始化 — 空 + 种子注释

MEMORY.md 初始内容只包含注释说明（如何使用这个文件），无实际记忆。Agent 在运行过程中自己积累。

**理由**: 官方定义 MEMORY.md 是"distilled essence, not raw logs"——应该由 Agent 自己写入，不是预填配置。

### D6: HEARTBEAT.md — 角色特定 checklist

每个角色的 HEARTBEAT.md 包含 3-5 个具体的周期性检查项（从当前 TOOLS.md 中迁移），格式为简短的 checklist。

**理由**: 官方定义 HEARTBEAT.md 应该"kept small to limit token burn"，是具体的待办而非监控指标表。

## Risks / Trade-offs

- **[Agent 行为变化]** → 重写后 Agent 的行为模式会显著改变（session startup 流程、memory 加载等）。**缓解**: 通过 e2e 测试验证基本通信功能，逐步观察调整。
- **[业务内容丢失]** → 迁移过程中可能遗漏有价值的内容。**缓解**: 逐文件对比，确保所有业务规则都迁移到正确位置。
- **[63 个文件批量重写]** → 大规模变更风险高。**缓解**: 按角色分批实施，每完成一个角色做一次 sanity check。
- **[中英混合风格]** → OpenClaw 模板示例是英文的，我们需要中文化。**缓解**: 保持结构对齐，内容用中文表达，关键术语保留英文（如 Red Lines、Heartbeat）。
