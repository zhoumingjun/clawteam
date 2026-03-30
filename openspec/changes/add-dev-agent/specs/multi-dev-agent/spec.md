## ADDED Requirements

### Requirement: Dev Agent 服务部署

`openclaw-agent-dev` 服务 SHALL 通过 docker-compose 启动。

### Requirement: Dev Agent Matrix 连接

Dev Agent SHALL 通过 Matrix channel 连接到 Synapse，状态为 running。

### Requirement: Dev Agent Gateway RPC

Gateway SHALL 能接收 RPC 调用并转发给 Dev Agent。

### Requirement: Matrix 通知发送

Dev Agent SHALL 能通过 Matrix channel 发送通知消息。

### Requirement: 多 Agent 配置分离

Dev Agent SHALL 有独立的配置目录和 volume。
