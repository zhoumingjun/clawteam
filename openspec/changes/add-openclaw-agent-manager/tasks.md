## 1. Synapse 配置更新

- [ ] 1.1 在 `configs/synapse/homeserver.yaml` 添加 `registration_shared_secret` 配置
- [ ] 1.2 验证 Synapse 配置正确（无格式错误）

## 2. Agent 配置目录创建

- [ ] 2.1 创建 `configs/agents/manager/` 目录
- [ ] 2.2 创建 Agent SOUL.md 配置文件
- [ ] 2.3 创建 Agent AGENTS.md 配置文件
- [ ] 2.4 创建 Agent HEARTBEAT.md 配置文件

## 3. Docker Compose 服务添加

- [ ] 3.1 在 docker-compose.yml 添加 openclaw-agent-manager 服务
- [ ] 3.2 配置服务使用镜像 `ghcr.io/openclaw/openclaw:main-slim`
- [ ] 3.3 配置 environment 变量（AGENT_ID, AGENT_PASSWORD, OPENCLAW_API_KEY, MATRIX_HOMESERVER）
- [ ] 3.4 配置 volume 挂载 `configs/agents/manager/:/app/agent`
- [ ] 3.5 配置 networks 使用 clawteam-network
- [ ] 3.6 配置 depends_on 确保在 Synapse 之后启动
- [ ] 3.7 配置 healthcheck 验证服务健康状态

## 4. 初始化脚本创建

- [ ] 4.1 创建 `scripts/openclaw-agent-init.sh` 脚本
- [ ] 4.2 脚本实现通过 registration_shared_secret 自动注册 Agent 用户
- [ ] 4.3 脚本验证注册成功

## 5. 环境变量和文档

- [ ] 5.1 在 .env.example 添加 OPENCLAW_AGENT_MANAGER_* 相关变量
- [ ] 5.2 更新 README.md 添加 Agent Manager 相关信息

## 6. 验证和测试

- [ ] 6.1 执行 `docker compose up -d` 启动服务
- [ ] 6.2 运行初始化脚本注册 Agent
- [ ] 6.3 验证服务状态 `docker compose ps`
- [ ] 6.4 通过 Element Web 验证人机交互正常
