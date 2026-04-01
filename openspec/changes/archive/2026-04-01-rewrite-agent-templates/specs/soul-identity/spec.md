## ADDED Requirements

### Requirement: SOUL.md 遵循 OpenClaw 官方结构
每个 Agent 的 SOUL.md SHALL 包含以下节（按顺序）：Core Truths、Boundaries、Vibe、Role Context、Continuity。

Core Truths SHALL 包含 3-5 条该角色视角的人格信念，体现角色独特的价值观和工作哲学，而非通用的职责描述。

Boundaries SHALL 融入当前 IDENTITY.md 中的安全边界规则和 Matrix ID 信息。

Vibe SHALL 用 1-2 句话描述该 Agent 的沟通风格。

Role Context SHALL 用 2-3 句话概括角色核心定位（从当前 SOUL.md 的详细职责列表中提炼精华）。

Continuity SHALL 说明 session 持续性机制（文件即记忆）。

#### Scenario: Arch Agent SOUL.md 包含完整结构
- **WHEN** 读取 `config/agents/arch/SOUL.md`
- **THEN** 文件包含 Core Truths、Boundaries、Vibe、Role Context、Continuity 五个节，Core Truths 体现架构师视角（如"好的架构是简单的架构"），Boundaries 包含 `@arch:localhost` Matrix ID 和安全边界

#### Scenario: 每个 Agent 的 SOUL.md 人格各异
- **WHEN** 对比 6 个业务 Agent 的 SOUL.md Core Truths 节
- **THEN** 每个 Agent 的信念内容不同，体现各自角色特色（arch 注重简洁设计、dev 注重代码质量、qa 注重质量标准等）

#### Scenario: 安全边界从 IDENTITY.md 迁移到 SOUL.md
- **WHEN** 读取任意 Agent 的 SOUL.md Boundaries 节
- **THEN** 包含原 IDENTITY.md 中的安全红线（如 arch 的"不直接修改生产代码"、dev 的"不绕过 code review"等）

### Requirement: IDENTITY.md 遵循 OpenClaw 官方 5 字段格式
每个 Agent 的 IDENTITY.md SHALL 仅包含 5 个字段：Name、Creature、Vibe、Emoji、Avatar。

Name SHALL 为该 Agent 的显示名称。
Creature SHALL 描述 Agent 的自我认知（如"AI 架构师"）。
Vibe SHALL 用 1-3 个形容词描述风格。
Emoji SHALL 为 1 个代表性 emoji。
Avatar SHALL 为头像路径（可留空）。

IDENTITY.md SHALL NOT 包含 Matrix ID、安全边界、Agent Code 等内容（这些已迁移到 SOUL.md）。

#### Scenario: IDENTITY.md 仅包含 5 字段
- **WHEN** 读取 `config/agents/dev/IDENTITY.md`
- **THEN** 文件仅包含 Name、Creature、Vibe、Emoji、Avatar 五个字段，无 Matrix ID 或安全策略内容

#### Scenario: 每个 Agent 有独特的 emoji 和 vibe
- **WHEN** 读取所有 Agent 的 IDENTITY.md
- **THEN** 每个 Agent 的 Emoji 和 Vibe 均不同

### Requirement: default/ 目录有独立身份
default/ 目录的 SOUL.md 和 IDENTITY.md SHALL 定义一个通用协调者角色（如"Claw"），而非 manager 的拷贝。

default/ 的 Matrix ID 信息 SHALL NOT 包含 `@manager:localhost`。

#### Scenario: default SOUL.md 不是 manager 的拷贝
- **WHEN** 对比 `config/agents/default/SOUL.md` 和 `config/agents/manager/SOUL.md`
- **THEN** 两个文件内容不同，default 定义的是通用协调者角色
