## Why

当前 OpenClaw Agent Manager 已成功连接到 Matrix，具备独立工作能力。需要验证多 Agent 协作场景：Manager Agent 接收 Human 任务后，能否正确拆解并分配给 Dev Agent。

## What Changes

- 测试 Manager Agent 接收 Human 任务
- 测试 Manager Agent 拆解任务并分配给 Dev Agent
- 验证任务在 Agent 间的流转

## Capabilities

### New Capabilities
- `multi-agent-collaboration`: 验证多 Agent 间的任务分配和协作流程

### Modified Capabilities
- 无

## Impact

- 新增测试脚本验证协作流程
- 积累多 Agent 协作经验
