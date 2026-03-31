## ADDED Requirements

### Requirement: USER.md 遵循 OpenClaw 官方格式
每个 Agent 的 USER.md SHALL 采用渐进式人类档案格式，包含以下字段：

- **Name** — 用户名称
- **What to call them** — 称呼方式
- **Timezone** — 时区
- **Context** — 关于用户的渐进式信息（关注点、项目、偏好等）

对于面向 manager 的 Agent（arch, qa, sre, research），"用户"指 Manager Agent。
对于 manager 和 default，"用户"指人类用户。
对于 dev，"用户"指 Manager Agent（通过 Manager 分配任务）。

USER.md SHALL 以引导性注释作为 Context 节的初始内容，提示 Agent 在交互过程中逐步补充。

#### Scenario: USER.md 包含正确字段
- **WHEN** 读取 `config/agents/manager/USER.md`
- **THEN** 包含 Name、What to call them、Timezone、Context 字段，Context 有引导性注释

#### Scenario: 不同角色的 USER.md 指向正确的"用户"
- **WHEN** 读取 `config/agents/arch/USER.md`
- **THEN** Name 指向 Manager Agent（因为 arch 主要接收 manager 分配的任务）

### Requirement: MEMORY.md 初始为空种子
每个 Agent 的 MEMORY.md SHALL 初始仅包含注释说明，解释该文件的用途和使用规则：

- 这是你的长期记忆文件
- 仅在 main session 中加载（安全原因）
- 记录重要事件、决策、教训的精华（不是原始日志）
- 定期从 daily notes 中提炼更新

MEMORY.md SHALL NOT 包含存储路径配置、记忆类型分类等"配置"内容。

#### Scenario: MEMORY.md 初始为空
- **WHEN** 读取任意 Agent 的 MEMORY.md
- **THEN** 文件仅包含注释说明，无实际记忆内容，无存储路径配置

#### Scenario: MEMORY.md 注释说明使用规则
- **WHEN** 读取 `config/agents/dev/MEMORY.md`
- **THEN** 注释中说明了仅在 main session 加载、记录精华而非原始日志等使用规则
