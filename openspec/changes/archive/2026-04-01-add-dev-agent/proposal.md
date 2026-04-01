## Why

SPEC-021 测试发现 OpenClaw Agent 通过 Gateway RPC 交互。需要部署第二个 Agent (Dev) 来验证多 Agent 协作流程：Gateway RPC 调用 → Agent 处理 → Matrix 通知。

## What Changes

- 在 docker-compose.yml 添加 dev-agent 服务
- 创建 dev-agent 配置文件
- 配置 dev-agent 的 Matrix channel
- 验证 Gateway RPC 调用 Agent

## Capabilities

### New Capabilities
- `multi-dev-agent`: 多 Agent 部署和协作

### Modified Capabilities
- 无

## Impact

- 新增 `openclaw-agent-dev` 服务
- 新增 `configs/agents/dev/` 配置目录
