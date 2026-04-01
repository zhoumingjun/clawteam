## ADDED Requirements

### Requirement: OpenClaw Matrix 配置持久化

`configs/agents/manager/openclaw.json` SHALL 包含 Matrix channel 的基础配置（plugins.enabled, channels.matrix.allowPrivateNetwork）。

### Requirement: Matrix Channel 初始化脚本

`scripts/openclaw-matrix-init.sh` SHALL 完成以下初始化:
1. 启用 matrix 插件
2. 配置 allowPrivateNetwork
3. 添加 channel 配置（homeserver, userId）
4. 验证连接状态

### Requirement: Docker Compose Volume 挂载

`docker-compose.yml` SHALL 挂载 `configs/agents/manager/openclaw.json` 到容器内 `/home/node/.openclaw/openclaw.json`。

### Requirement: 环境变量注入

密码和 access_token SHALL 通过 environment 变量注入，不存储在配置文件中。

### Requirement: 配置验证

容器启动后 SHALL 执行配置验证，确保 Matrix channel 状态为 `running`。
