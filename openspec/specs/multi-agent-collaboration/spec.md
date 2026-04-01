## Purpose

定义多 Agent 协作流程，包括任务接收、拆解和消息传递。

## Requirements

### Requirement: Manager Agent 接收 Human 任务

Manager Agent SHALL 通过 Matrix 接收 Human 用户发送的任务指令。

#### Scenario: Human 在 Matrix room 中发送任务指令
- **WHEN** Human 用户在 Claw Team Matrix room 中发送一条任务指令消息
- **THEN** Manager Agent 接收到该消息并确认收到任务

### Requirement: Manager Agent 任务拆解

Manager Agent SHALL 能够分析任务并拆解为可执行的子任务。

#### Scenario: Manager Agent 将复合任务拆解为子任务
- **WHEN** Manager Agent 接收到一个包含多个步骤的复合任务
- **THEN** Manager Agent 将其分析并拆解为独立的可执行子任务

### Requirement: Agent 间消息传递

Manager Agent SHALL 能够通过 Matrix 向其他 Agent 发送任务分配消息。

#### Scenario: Manager Agent 向 Dev Agent 分配子任务
- **WHEN** Manager Agent 拆解任务后需要将子任务分配给 Dev Agent
- **THEN** Manager Agent 通过 Matrix room 向 Dev Agent 发送任务分配消息

### Requirement: 任务响应验证

测试 SHALL 验证 Manager Agent 能在 Matrix room 中响应 Human 消息。

#### Scenario: Manager Agent 在 Matrix room 中响应 Human 消息
- **WHEN** Human 用户在 Matrix room 中发送消息并等待响应
- **THEN** Manager Agent 在同一 Matrix room 中发送响应消息
