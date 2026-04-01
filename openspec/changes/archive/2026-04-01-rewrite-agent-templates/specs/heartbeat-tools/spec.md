## ADDED Requirements

### Requirement: HEARTBEAT.md 包含角色特定的简短 checklist
每个 Agent 的 HEARTBEAT.md SHALL 包含 3-5 个角色特定的周期性检查项，格式为简短的 checklist。

检查项 SHALL 从当前 TOOLS.md 的心跳检查节迁移而来，并精简为具体动作。

不同角色的检查项示例：
- **manager**: 检查任务队列状态、团队阻塞问题、向 human 汇报进度
- **dev**: 检查 CI/CD 状态、代码质量告警、依赖更新
- **arch**: 检查设计评审队列、技术债务、文档同步
- **qa**: 检查测试执行状态、缺陷跟踪、测试覆盖率
- **sre**: 检查服务健康状态、资源使用、告警、部署状态
- **research**: 检查研究任务进度、技术追踪更新

HEARTBEAT.md SHALL 保持简短（token burn 最小化），每个检查项不超过一行。

#### Scenario: 角色特定的心跳检查
- **WHEN** 读取 `config/agents/sre/HEARTBEAT.md`
- **THEN** 包含 SRE 特定的检查项（服务健康、资源、告警、部署），而非通用监控模板

#### Scenario: 不同角色的 HEARTBEAT.md 内容不同
- **WHEN** 对比所有 Agent 的 HEARTBEAT.md
- **THEN** 每个角色的检查项不同，体现各自职责

#### Scenario: HEARTBEAT.md 保持简短
- **WHEN** 读取任意 Agent 的 HEARTBEAT.md
- **THEN** 文件不超过 15 行（含注释），每个检查项不超过一行

### Requirement: TOOLS.md 改为环境特定备忘录
每个 Agent 的 TOOLS.md SHALL 仅包含该 Agent 的本地环境配置备忘，格式为"cheat sheet"。

内容 SHALL 包含：
- Matrix 配置（homeserver URL、团队房间名等环境特定信息）
- 该角色常用的工具/命令速查
- 环境特定的笔记

TOOLS.md SHALL NOT 包含：
- 能力矩阵或工具功能列表
- 心跳检查项（已迁移到 HEARTBEAT.md）
- 详细的工具使用说明（属于 SKILL.md）

#### Scenario: TOOLS.md 是环境备忘录
- **WHEN** 读取 `config/agents/dev/TOOLS.md`
- **THEN** 包含 Matrix 配置信息和常用命令速查，无能力矩阵或心跳检查项

#### Scenario: TOOLS.md 不含心跳检查
- **WHEN** 读取任意 Agent 的 TOOLS.md
- **THEN** 文件不包含"心跳"、"检查频率"、"告警阈值"等心跳相关内容
