## Context

SPEC-021 验证了 Manager Agent 部署成功，但发现 Agent 通过 Gateway RPC 交互而非 Matrix bot 模式。需要部署 Dev Agent 测试多 Agent 协作。

## Goals / Non-Goals

**Goals:**
- 部署 Dev Agent 服务
- 验证 Dev Agent Matrix 连接
- 测试 Gateway RPC 调用 Agent
- 测试 Agent → Matrix 通知

**Non-Goals:**
- 不测试完整的代码开发流程
- 不测试 Agent 间直接通信

## Architecture

```
Human → Gateway RPC (openclaw agent) → Agent (Manager/Dev)
                                    ↓
                              Matrix channel → Notification
```

## Implementation

### 1. Dev Agent 配置
类似 Manager Agent，但使用不同配置：
- 镜像: `ghcr.io/openclaw/openclaw:main-slim`
- 服务名: `openclaw-agent-dev`
- 用户名: `@openclaw-agent-dev:localhost`
- 端口: 不暴露（仅 Gateway 内部访问）

### 2. 关键配置
```yaml
services:
  openclaw-agent-dev:
    environment:
      - OPENCLAW_AGENT_ID=dev
      - OPENCLAW_MATRIX_HOMESERVER=http://synapse:8008
      - OPENCLAW_AGENT_PASSWORD=${OPENCLAW_DEV_AGENT_PASSWORD}
    volumes:
      - ./configs/agents/dev:/app/agent:ro
      - ./volumes/openclaw-dev-data:/home/node/.openclaw:rw
```

### 3. 测试步骤
1. 启动 Dev Agent 服务
2. 验证 Matrix channel 连接
3. 通过 `openclaw agent` 发送测试消息
4. 验证响应和 Matrix 通知

## Risks / Trade-offs

- **风险**: 两个 Agent 可能共享同一 Gateway
  - **缓解**: 通过不同 service name 区分
- **风险**: Matrix 用户冲突
  - **缓解**: 使用不同用户名 (openclaw-agent-dev)

## Open Questions

1. ~~Dev Agent 是否需要独立部署还是与 Manager 共享 Gateway？~~ ✅ 各自独立部署
2. ~~Agent 间通信如何实现？（通过 Matrix room？）~~ ✅ 已创建 clawteam-agents 房间

## Completed: Matrix Room Setup (SPEC-022)

### Room Architecture

```
Matrix Homeserver (Synapse)
├── Claw Team (主房间)
│   └── 所有用户和 Agent (@human, @manager, @dev, @arch, @qa, @sre, @research, @openclaw-agent, @openclaw-agent-dev)
│
└── clawteam-agents (Agent 专用房间)
    └── 仅 Agent 账户 (@openclaw-agent, @openclaw-agent-dev, @arch, @dev, @qa, @sre, @research)
```

### 实现命令

```bash
# 创建 agents 房间
curl -X POST "http://localhost:8008/_matrix/client/r0/createRoom" \
  -H "Authorization: Bearer <manager_token>" \
  -d '{"name": "clawteam-agents", "visibility": "private", "invite": ["@openclaw-agent-dev:localhost"]}'

# 邀请其他 Agent
curl -X POST "http://localhost:8008/_matrix/client/r0/rooms/!dZvtMsoEkcegNIyzHS:localhost/invite" \
  -H "Authorization: Bearer <manager_token>" \
  -d '{"user_id": "@arch:localhost"}'
```
