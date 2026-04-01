## ADDED Requirements

### Requirement: AGENTS.md 包含 OpenClaw 官方必需节
每个 Agent 的 AGENTS.md SHALL 包含以下官方必需节：

1. **Session Startup** — 定义启动时依次读取 SOUL.md → USER.md → daily notes → MEMORY.md 的流程
2. **Memory** — 定义 daily notes（`memory/YYYY-MM-DD.md`）和 MEMORY.md 的使用规则
3. **Red Lines** — 定义不可逾越的行为红线（不泄露私密数据、不执行破坏性命令等）
4. **Group Chat** — 定义 Matrix 团队房间内的发言规则（何时回复、何时沉默）
5. **Heartbeat** — 定义收到心跳时的行为（读 HEARTBEAT.md、执行检查、回复 HEARTBEAT_OK）
6. **Tools** — 引用 TOOLS.md 和各 SKILL.md 的使用方式

#### Scenario: Session Startup 节存在且正确
- **WHEN** 读取任意 Agent 的 AGENTS.md
- **THEN** Session Startup 节定义了按序读取 SOUL.md → USER.md → daily notes → MEMORY.md 的流程

#### Scenario: Red Lines 节包含安全边界
- **WHEN** 读取任意 Agent 的 AGENTS.md Red Lines 节
- **THEN** 包含至少 4 条红线（不泄露数据、不执行破坏性操作、遇到不确定时询问等）

### Requirement: AGENTS.md 保留业务协作规则
每个 Agent 的 AGENTS.md SHALL 在官方必需节之后，包含以下业务扩展节：

1. **Team Protocol** — 团队成员列表（含完整 Matrix ID）和 @mention 规则
2. **Task Protocol** — 任务卡片格式和流转规则（仅 manager 需要完整版，其他角色简化版）
3. **Deliverables** — 该角色的交付物标准和质量要求

当前 AGENTS.md 中的完整 Matrix @mention 规则（完整 MXID、m.mentions、requireMention 等）SHALL 保留在 Team Protocol 节。

#### Scenario: Team Protocol 保留 Matrix mention 规则
- **WHEN** 读取 `config/agents/manager/AGENTS.md` 的 Team Protocol 节
- **THEN** 包含完整的团队成员表（带 Matrix ID）和 @mention 规则（完整 MXID、m.mentions 等）

#### Scenario: 非 manager Agent 有简化的协作规则
- **WHEN** 读取 `config/agents/dev/AGENTS.md`
- **THEN** Team Protocol 包含团队成员列表，Task Protocol 仅包含接收任务的流程（无任务分发），Deliverables 包含 dev 角色特定的交付物标准

### Requirement: Group Chat 节针对 Matrix 团队房定制
AGENTS.md 的 Group Chat 节 SHALL 针对 Claw Team 的 Matrix 团队房场景进行定制，包含：

- 何时回复（被 @ 时必须回复、能提供有价值信息时回复）
- 何时沉默（未被 @ 且非自己职责范围、他人已回答、纯闲聊）
- 团队房出站规则（每条消息必须带至少一名收件人的完整 MXID）
- 禁止广播式发言

#### Scenario: Group Chat 包含 Matrix 团队房规则
- **WHEN** 读取任意 Agent 的 AGENTS.md Group Chat 节
- **THEN** 包含回复条件、沉默条件、出站规则（必须带 MXID）和禁止广播规则
