## Why

当前 Claw Team 的 Matrix 基础设施（Synapse + Element Web）已正常运行，但 Agent 团队尚未接入。需要集成 OpenClaw Agent Manager 作为第一个试点 Agent，实现人机协作的完整闭环。

## What Changes

- 新增 `openclaw-agent-manager` 服务到 docker-compose.yml
- 在 Synapse 中配置 `registration_shared_secret` 实现 Agent 自动注册
- 通过 volume 挂载 Agent 配置目录 `configs/agents/manager/`
- 创建 Agent 初始化脚本，支持自动注册到 Matrix

## Capabilities

### New Capabilities
- `openclaw-agent-manager`: 将 OpenClaw Agent Manager 集成到 Claw Team，作为 Manager Agent 通过 Matrix 协议与人交互

### Modified Capabilities
- 无

## Impact

- 新增服务：`openclaw-agent-manager`
- 修改配置：`configs/synapse/homeserver.yaml`（添加 registration_shared_secret）
- 新增配置：`configs/agents/manager/` 目录及 Agent 配置文件
- 新增脚本：`scripts/openclaw-agent-init.sh`
