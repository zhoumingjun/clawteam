## 1. Dev Agent 配置准备

- [ ] 1.1 创建 `configs/agents/dev/` 配置目录
- [ ] 1.2 创建 `configs/agents/dev/openclaw.json` 配置文件
- [ ] 1.3 创建 `configs/agents/dev/SOUL.md` Agent 定义
- [ ] 1.4 创建 `configs/agents/dev/AGENTS.md` 团队配置

## 2. Docker Compose 更新

- [ ] 2.1 添加 `openclaw-agent-dev` 服务
- [ ] 2.2 配置 volume 挂载
- [ ] 2.3 配置环境变量
- [ ] 2.4 添加 healthcheck

## 3. Synapse 用户注册

- [ ] 3.1 注册 `openclaw-agent-dev` 用户到 Synapse
- [ ] 3.2 设置用户密码

## 4. 服务启动和验证

- [ ] 4.1 启动 Dev Agent 服务
- [ ] 4.2 验证 Matrix channel 状态
- [ ] 4.3 验证 Gateway RPC 调用

## 5. 交互测试

- [ ] 5.1 通过 Gateway 发送测试消息
- [ ] 5.2 验证 Agent 响应
- [ ] 5.3 验证 Matrix 通知发送
