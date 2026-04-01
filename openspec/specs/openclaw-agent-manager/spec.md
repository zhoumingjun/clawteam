## Purpose

定义 OpenClaw Agent Manager 服务的启动、配置和健康检查。

## Requirements

### Requirement: OpenClaw Agent Manager 服务启动

openclaw-agent-manager 服务 SHALL 通过 docker-compose 启动，并正确配置所有必需环境变量。

#### Scenario: 通过 docker-compose 启动 Agent Manager 服务
- **WHEN** 运行 `docker compose up openclaw-agent-manager` 且所有必需环境变量已配置
- **THEN** 服务容器成功启动且无报错

### Requirement: OpenClaw Agent Manager 配置挂载

Agent 配置文件目录 SHALL 通过 volume 挂载到容器内 `/app/agent` 目录。

#### Scenario: 配置目录通过 volume 挂载到容器
- **WHEN** 容器启动并检查 `/app/agent` 目录
- **THEN** 主机上的 Agent 配置文件在容器内 `/app/agent` 目录中可访问

### Requirement: OpenClaw Agent Manager 自动注册

Agent SHALL 通过 Synapse registration_shared_secret 自动注册到 Matrix 服务器，无需手动创建用户。

#### Scenario: Agent 首次启动时自动注册到 Matrix
- **WHEN** Agent 首次启动且 Matrix 服务器上不存在该用户
- **THEN** Agent 使用 registration_shared_secret 自动完成注册，无需手动干预

### Requirement: OpenClaw Agent Manager 连接 Matrix

Agent SHALL 使用 MATRIX_HOMESERVER 环境变量连接 Synapse 服务器，实现人机消息交互。

#### Scenario: Agent 通过 MATRIX_HOMESERVER 连接 Synapse
- **WHEN** Agent 启动并读取 MATRIX_HOMESERVER 环境变量
- **THEN** Agent 成功连接到指定的 Synapse 服务器并能收发消息

### Requirement: OpenClaw Agent Manager 健康检查

服务 SHALL 配置健康检查，确保 Agent 正常运行时 docker compose ps 显示 healthy 状态。

#### Scenario: 正常运行的 Agent 显示 healthy 状态
- **WHEN** Agent 服务正常运行并通过健康检查
- **THEN** `docker compose ps` 显示该服务状态为 `healthy`

### Requirement: Synapse 支持 Agent 注册

Synapse SHALL 配置 registration_shared_secret，支持 Agent 通过 shared secret 注册。

#### Scenario: Synapse 配置 registration_shared_secret
- **WHEN** 检查 Synapse 配置文件
- **THEN** `registration_shared_secret` 已设置，允许 Agent 通过 shared secret 进行注册

### Requirement: 服务网络隔离

openclaw-agent-manager SHALL 与 synapse 服务在同一网络 (clawteam-network)，确保通信正常。

#### Scenario: Agent Manager 与 Synapse 在同一 Docker 网络
- **WHEN** 检查 docker-compose 网络配置
- **THEN** openclaw-agent-manager 和 synapse 均连接到 `clawteam-network` 网络

### Requirement: 环境变量配置

Agent SHALL 从环境变量读取:
- AGENT_ID: Agent 用户名 (manager)
- AGENT_PASSWORD: Agent Matrix 密码
- OPENCLAW_API_KEY: OpenClaw API 密钥
- MATRIX_HOMESERVER: Matrix 服务器地址 (http://synapse:8008)

#### Scenario: Agent 从环境变量读取所有必需配置
- **WHEN** Agent 启动并读取环境变量 AGENT_ID、AGENT_PASSWORD、OPENCLAW_API_KEY、MATRIX_HOMESERVER
- **THEN** Agent 使用这些环境变量值完成配置初始化，不依赖硬编码值
