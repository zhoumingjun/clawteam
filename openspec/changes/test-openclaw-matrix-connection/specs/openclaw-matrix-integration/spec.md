## ADDED Requirements

### Requirement: Agent Matrix 插件启用

OpenClaw Agent SHALL 启用 `@openclaw/matrix` 插件以支持 Matrix 协议。

### Requirement: Agent Matrix 登录验证

Agent SHALL 能够使用 Matrix 用户名和密码登录 Synapse 并保持连接。

### Requirement: Agent Matrix 连接状态

Agent SHALL 通过 `openclaw channels status` 显示 Matrix channel 为 `running` 状态。

### Requirement: Agent 消息接收

Agent SHALL 能够接收来自 Matrix room 的消息（需要配置 autoJoin）。

### Requirement: 自动化测试脚本

`tests/matrix/test-connection.sh` SHALL 验证 Agent 与 Matrix 的连接状态。
