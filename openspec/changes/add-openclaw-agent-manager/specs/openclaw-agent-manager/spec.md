## ADDED Requirements

### Requirement: OpenClaw Agent Manager 服务启动

openclaw-agent-manager 服务 SHALL 通过 docker-compose 启动，并正确配置所有必需环境变量。

### Requirement: OpenClaw Agent Manager 配置挂载

Agent 配置文件目录 SHALL 通过 volume 挂载到容器内 `/app/agent` 目录。

### Requirement: OpenClaw Agent Manager 自动注册

Agent SHALL 通过 Synapse registration_shared_secret 自动注册到 Matrix 服务器，无需手动创建用户。

### Requirement: OpenClaw Agent Manager 连接 Matrix

Agent SHALL 使用 MATRIX_HOMESERVER 环境变量连接 Synapse 服务器，实现人机消息交互。

### Requirement: OpenClaw Agent Manager 健康检查

服务 SHALL 配置健康检查，确保 Agent 正常运行时 docker compose ps 显示 healthy 状态。

### Requirement: Synapse 支持 Agent 注册

Synapse SHALL 配置 registration_shared_secret，支持 Agent 通过 shared secret 注册。

### Requirement: 服务网络隔离

openclaw-agent-manager SHALL 与 synapse 服务在同一网络 (clawteam-network)，确保通信正常。

### Requirement: 环境变量配置

Agent SHALL 从环境变量读取:
- AGENT_ID: Agent 用户名 (manager)
- AGENT_PASSWORD: Agent Matrix 密码
- OPENCLAW_API_KEY: OpenClaw API 密钥
- MATRIX_HOMESERVER: Matrix 服务器地址 (http://synapse:8008)
