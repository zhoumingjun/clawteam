## Purpose

定义 OpenClaw Agent 与 Matrix 协议的集成，包括登录、连接和消息收发。

## Requirements

### Requirement: Agent Matrix 插件启用

OpenClaw Agent SHALL 启用 `@openclaw/matrix` 插件以支持 Matrix 协议。

#### Scenario: 启用 @openclaw/matrix 插件
- **WHEN** 检查 Agent 的插件配置
- **THEN** `@openclaw/matrix` 插件已列入 `plugins.enabled` 且处于激活状态

### Requirement: Agent Matrix 登录验证

Agent SHALL 能够使用 Matrix 用户名和密码登录 Synapse 并保持连接。

#### Scenario: Agent 使用凭据登录 Synapse
- **WHEN** Agent 使用配置的用户名和密码向 Synapse 发起登录请求
- **THEN** 登录成功且 Agent 保持与 Synapse 的持久连接

### Requirement: Agent Matrix 连接状态

Agent SHALL 通过 `openclaw channels status` 显示 Matrix channel 为 `running` 状态。

#### Scenario: 查询 Matrix channel 状态为 running
- **WHEN** 执行 `openclaw channels status` 命令
- **THEN** 输出中 Matrix channel 状态显示为 `running`

### Requirement: Agent 消息接收

Agent SHALL 能够接收来自 Matrix room 的消息（需要配置 autoJoin）。

#### Scenario: Agent 接收 Matrix room 消息
- **WHEN** 用户在 Agent 已加入的 Matrix room 中发送消息
- **THEN** Agent 成功接收到该消息

### Requirement: 自动化测试脚本

`tests/matrix/test-connection.sh` SHALL 验证 Agent 与 Matrix 的连接状态。

#### Scenario: 运行测试脚本验证 Matrix 连接
- **WHEN** 执行 `tests/matrix/test-connection.sh` 测试脚本
- **THEN** 脚本验证 Agent 与 Matrix 的连接状态并返回成功退出码
