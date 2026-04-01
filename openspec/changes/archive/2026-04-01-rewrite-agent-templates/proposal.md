## Why

当前 `config/agents/` 下 7 个 Agent 的模板文件内容与 OpenClaw 官方模板规范严重不匹配。SOUL.md 写成了 Job Description、IDENTITY.md 当成了安全策略、MEMORY.md 变成了存储配置、HEARTBEAT.md 是通用监控模板（7 个 agent 完全相同）。内容虽然有价值，但放在了错误的文件里，导致 OpenClaw 运行时无法正确加载 Agent 的身份、记忆和行为规则。需要按官方模板定义重写，让每个文件承担它该承担的职责。

## What Changes

- **重写 SOUL.md（7 个 agent）**：从 Job Description 改为有人格的身份定义（核心真理 + 价值观 + 行为边界 + Vibe），融入当前 IDENTITY.md 中的 Matrix ID 和安全边界
- **重写 IDENTITY.md（7 个 agent）**：改为官方的 5 字段轻量元数据（Name / Creature / Vibe / Emoji / Avatar）
- **重写 AGENTS.md（7 个 agent）**：补充 Session Startup、Memory 规则、Red Lines、Group Chat 行为等官方必需节，保留有价值的协作规则和交付物标准
- **重写 USER.md（7 个 agent）**：改为渐进式人类档案格式（Name / 称呼 / Timezone / Context）
- **重写 MEMORY.md（7 个 agent）**：清空为初始种子内容，让 Agent 运行时自己积累
- **重写 HEARTBEAT.md（7 个 agent）**：从通用监控模板改为角色特定的简短 checklist，迁入当前 TOOLS.md 中的心跳检查项
- **重写 TOOLS.md（7 个 agent）**：从能力矩阵改为环境特定备忘录（Matrix 配置、SSH、本地工具笔记）
- **新增 BOOTSTRAP.md（7 个 agent）**：添加官方的首次运行初始化机制
- **重构 default/ 目录**：从 manager 的完全拷贝改为通用 fallback 模板

## Capabilities

### New Capabilities
- `soul-identity`: 按 OpenClaw 官方规范重写 SOUL.md 和 IDENTITY.md，建立正确的 Agent 身份与人格模型
- `agents-workspace`: 按 OpenClaw 官方规范重写 AGENTS.md，建立完整的工作空间操作手册（Session Startup / Memory / Red Lines / Group Chat / Heartbeat / Tools）
- `user-memory`: 按 OpenClaw 官方规范重写 USER.md 和 MEMORY.md，建立正确的用户档案与记忆机制
- `heartbeat-tools`: 按 OpenClaw 官方规范重写 HEARTBEAT.md 和 TOOLS.md，建立正确的心跳检查与工具备忘
- `bootstrap`: 为每个 Agent 添加 BOOTSTRAP.md 首次运行初始化文件

### Modified Capabilities

（无已有 spec 需要修改）

## Impact

- **文件变更**: `config/agents/` 下 7 个目录 × 8 个文件 = 56 个文件重写 + 7 个 BOOTSTRAP.md 新增 = 63 个文件
- **运行时行为**: Agent 的 Session Startup 流程、Memory 加载、Heartbeat 行为将完全改变
- **测试**: `tests/test_repo_layout.py` 需要更新（新增 BOOTSTRAP.md 到检查列表）
- **无 API/依赖变更**: 纯配置文件重写，不影响 Docker、Compose、脚本等
