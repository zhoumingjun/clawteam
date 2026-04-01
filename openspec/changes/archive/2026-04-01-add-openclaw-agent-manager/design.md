## Context

Claw Team 项目旨在构建 AI 软件研发工厂，通过多个专业化 AI Agent 覆盖软件开发的全生命周期。Matrix 协议作为人机/机机交互的基础设施已部署完成（Synapse + Element Web）。当前需要接入第一个 Agent——OpenClaw Agent Manager，实现 Manager Agent 通过 Matrix 与人交互。

## Goals / Non-Goals

**Goals:**
- 将 OpenClaw Agent Manager 集成到 Claw Team
- 通过 Matrix 协议实现人机交互
- 支持 Agent 自动注册到 Synapse（通过 shared secret）
- Agent 配置通过 volume 挂载，提高可维护性

**Non-Goals:**
- 完整 Agent 团队部署（其他 Agent 后续迭代）
- 高可用或生产级部署
- 自定义 Agent 定制

## Decisions

### 1. Docker 镜像
**决定**: 使用 `ghcr.io/openclaw/openclaw:main-slim`

**理由**: verified 镜像，slim 版本适合容器化部署

### 2. 服务命名
**决定**: 服务名 `openclaw-agent-manager`，容器名 `clawteam-openclaw-agent-manager`

**理由**: 避免与项目名称 "Claw Team" 混淆，明确标识为 OpenClaw 提供的 Manager Agent

### 3. 环境变量配置
**决定**: 通过 environment 或 .env 注入必需变量

**变量列表**:
- `MATRIX_HOMESERVER=http://synapse:8008` (Matrix 服务器地址)
- `AGENT_ID=manager` (Agent 用户名)
- `AGENT_PASSWORD` (Agent Matrix 密码)
- `OPENCLAW_API_KEY` (OpenClaw API 密钥)

**理由**:
- `MATRIX_HOMESERVER` 替代旧的 `CONDUIT_SERVER`，明确指向 Synapse
- 密码和 API Key 通过环境变量注入，不写入配置文件

### 4. Agent 配置挂载
**决定**: 通过 volume 挂载 `configs/agents/manager/` 到容器内配置目录

**理由**:
- 配置与代码分离，便于维护和更新
- 避免环境变量中存储复杂配置

### 5. Synapse 自动注册
**决定**: 在 `configs/synapse/homeserver.yaml` 添加 `registration_shared_secret`

**理由**:
- 支持 Agent 通过 shared secret 自动注册，无需手动创建用户
- 配合 Agent 初始化脚本实现自动化

### 6. 网络配置
**决定**: 使用 `clawteam-network` 与 synapse、element 共享网络

**理由**: Agent 需要与 Synapse 通信，必须在同一网络

## Risks / Trade-offs

- **风险**: OpenClaw Agent 兼容性
  - **缓解**: 先用 Manager Agent 试点，验证集成方案后再扩展

- **风险**: Agent 配置复杂性
  - **缓解**: 通过 volume 挂载简化配置管理

## Migration Plan

1. 更新 `docker-compose.yml` 添加 openclaw-agent-manager 服务
2. 更新 `configs/synapse/homeserver.yaml` 添加 registration_shared_secret
3. 创建 `configs/agents/manager/` 目录及配置文件
4. 创建 `scripts/openclaw-agent-init.sh` 初始化脚本
5. 执行 `docker compose up -d` 启动服务
6. 运行初始化脚本注册 Agent 用户
7. 通过 Element Web 验证人机交互

## Open Questions

- OpenClaw Agent 与 Matrix 的具体集成方式（是否需要额外配置）
- Agent 初始化脚本的具体实现（取决于 OpenClaw 文档）
