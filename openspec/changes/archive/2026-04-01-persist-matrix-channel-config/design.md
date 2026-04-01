## Context

SPEC-019 验证了 OpenClaw Agent 能成功连接 Matrix，但配置存在于容器内存中，容器重启后会丢失。需要将配置固化。

## Goals / Non-Goals

**Goals:**
- 将 OpenClaw Matrix channel 配置持久化
- 容器重启后配置保持不变
- 自动化初始化脚本

**Non-Goals:**
- 不修改 OpenClaw 核心配置结构
- 不实现 Agent 自动加入 room

## Decisions

### 1. 配置持久化方式
**决定**: 通过 volume 挂载预配置的 `openclaw.json`

**理由**:
- OpenClaw 配置存储在 `~/.openclaw/openclaw.json`
- 挂载文件覆盖容器内配置，实现持久化
- 避免复杂的 environment 变量嵌套

### 2. 配置目录结构
```
configs/agents/manager/
├── openclaw.json        # OpenClaw 配置文件
├── SOUL.md             # Agent 灵魂配置
├── AGENTS.md           # Agent 团队配置
└── HEARTBEAT.md        # 心跳配置
```

### 3. 初始化脚本
**决定**: 创建 `scripts/openclaw-matrix-init.sh`

**职责**:
- 启用 matrix 插件
- 配置 allowPrivateNetwork
- 添加 channel 配置
- 验证连接状态

### 4. Docker Compose 更新
在 volume 挂载中添加 `openclaw.json`:
```yaml
volumes:
  - ./configs/agents/manager/openclaw.json:/home/node/.openclaw/openclaw.json:ro
```

## Implementation Details

### openclaw.json 结构
```json
{
  "meta": {
    "lastTouchedVersion": "2026.3.25"
  },
  "plugins": {
    "entries": {
      "matrix": {
        "enabled": true
      }
    }
  },
  "channels": {
    "matrix": {
      "enabled": true,
      "allowPrivateNetwork": true,
      "homeserver": "http://synapse:8008",
      "userId": "@openclaw-agent:localhost"
    }
  }
}
```

**注意**: password 和 access_token 不能固化到文件（安全考虑），需要通过 environment 变量或 secrets 管理。

## Risks / Trade-offs

- **风险**: openclaw.json 版本不兼容
  - **缓解**: 使用 `openclaw config validate` 验证配置

- **风险**: 密码明文存储
  - **缓解**: 通过 environment 变量注入，不存储在文件中

## Migration Plan

1. 创建 `configs/agents/manager/openclaw.json`
2. 创建 `scripts/openclaw-matrix-init.sh`
3. 更新 docker-compose.yml volume 挂载
4. 测试容器重启后配置保持
