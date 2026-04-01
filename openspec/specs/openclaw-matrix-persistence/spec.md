## Purpose

定义 OpenClaw Matrix 配置的持久化方案，确保重启后配置不丢失。

## Requirements

### Requirement: OpenClaw Matrix 配置持久化

`configs/agents/manager/openclaw.json` SHALL 包含 Matrix channel 的基础配置（plugins.enabled, channels.matrix.allowPrivateNetwork）。

#### Scenario: openclaw.json 包含 Matrix 基础配置
- **WHEN** 检查 `configs/agents/manager/openclaw.json` 文件内容
- **THEN** 文件包含 `plugins.enabled` 和 `channels.matrix.allowPrivateNetwork` 配置项

### Requirement: Matrix Channel 初始化脚本

`scripts/openclaw-matrix-init.sh` SHALL 完成以下初始化:
1. 启用 matrix 插件
2. 配置 allowPrivateNetwork
3. 添加 channel 配置（homeserver, userId）
4. 验证连接状态

#### Scenario: 初始化脚本完成 Matrix channel 配置
- **WHEN** 执行 `scripts/openclaw-matrix-init.sh` 初始化脚本
- **THEN** matrix 插件启用、allowPrivateNetwork 已配置、channel 已添加，且连接状态验证通过

### Requirement: Docker Compose Volume 挂载

`docker-compose.yml` SHALL 挂载 `configs/agents/manager/openclaw.json` 到容器内 `/home/node/.openclaw/openclaw.json`。

#### Scenario: 配置文件通过 volume 挂载到容器内
- **WHEN** 容器启动后检查 `/home/node/.openclaw/openclaw.json`
- **THEN** 文件内容与主机上的 `configs/agents/manager/openclaw.json` 一致

### Requirement: 环境变量注入

密码和 access_token SHALL 通过 environment 变量注入，不存储在配置文件中。

#### Scenario: 敏感信息通过环境变量注入而非配置文件存储
- **WHEN** 检查 `configs/agents/manager/openclaw.json` 配置文件
- **THEN** 文件中不包含密码或 access_token，这些值通过环境变量注入

### Requirement: 配置验证

容器启动后 SHALL 执行配置验证，确保 Matrix channel 状态为 `running`。

#### Scenario: 容器启动后验证 Matrix channel 状态
- **WHEN** 容器启动完成并执行配置验证
- **THEN** Matrix channel 状态确认为 `running`
