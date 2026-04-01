## Purpose

定义 BOOTSTRAP.md 首次启动引导流程，确保 Agent 初始化标准化。

## Requirements

### Requirement: 每个 Agent 有 BOOTSTRAP.md 首次运行文件
每个 Agent 目录 SHALL 包含 BOOTSTRAP.md 文件，作为首次运行初始化引导。

BOOTSTRAP.md SHALL 包含：
- 欢迎语和角色介绍
- 引导 Agent 确认自己的身份（读取 SOUL.md 和 IDENTITY.md）
- 引导 Agent 熟悉工作空间（读取 AGENTS.md、TOOLS.md）
- 引导 Agent 在 Matrix 团队房间中发送首条消息（自我介绍）
- 指示完成初始化后删除 BOOTSTRAP.md

BOOTSTRAP.md 的内容 SHALL 因角色而异，包含角色特定的首次任务。

#### Scenario: BOOTSTRAP.md 存在于每个 Agent 目录
- **WHEN** 检查 `config/agents/arch/BOOTSTRAP.md`
- **THEN** 文件存在且包含首次运行引导内容

#### Scenario: BOOTSTRAP.md 包含自我删除指令
- **WHEN** 读取任意 Agent 的 BOOTSTRAP.md
- **THEN** 文件末尾指示 Agent 完成初始化后删除此文件

#### Scenario: 不同角色的 BOOTSTRAP.md 有角色特定内容
- **WHEN** 读取 `config/agents/sre/BOOTSTRAP.md`
- **THEN** 包含 SRE 特定的首次任务（如检查部署环境、验证监控配置），与 dev 的 BOOTSTRAP.md 内容不同

### Requirement: test_repo_layout 检查 BOOTSTRAP.md
`tests/test_repo_layout.py` 的 `test_agent_workspace_files` SHALL 将 BOOTSTRAP.md 添加到检查列表。

#### Scenario: 测试检查 BOOTSTRAP.md 存在
- **WHEN** 运行 `test_agent_workspace_files`
- **THEN** 验证每个 Agent 目录下 BOOTSTRAP.md 存在
