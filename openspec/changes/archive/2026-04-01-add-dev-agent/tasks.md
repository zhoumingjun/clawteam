## 1. Dev Agent 配置准备

- [x] 1.1 创建 `configs/agents/dev/` 配置目录
- [x] 1.2 创建 `configs/agents/dev/openclaw.json` 配置文件
- [x] 1.3 创建 `configs/agents/dev/SOUL.md` Agent 定义
- [x] 1.4 创建 `configs/agents/dev/AGENTS.md` 团队配置

## 2. Docker Compose 更新

- [x] 2.1 添加 `openclaw-agent-dev` 服务
- [x] 2.2 配置 volume 挂载
- [x] 2.3 配置环境变量
- [x] 2.4 添加 healthcheck

## 3. Synapse 用户注册

- [x] 3.1 注册 `openclaw-agent-dev` 用户到 Synapse
- [x] 3.2 设置用户密码

## 4. 服务启动和验证

- [x] 4.1 启动 Dev Agent 服务
- [x] 4.2 验证 Matrix channel 状态
- [x] 4.3 验证 Gateway RPC 调用

## 5. 交互测试

- [ ] 5.1 通过 Gateway 发送测试消息
- [ ] 5.2 验证 Agent 响应
- [ ] 5.3 验证 Matrix 通知发送

## 6. Matrix Room Setup (SPEC-022)

- [x] 6.1 创建 `clawteam-agents` 房间用于 Agent 间通信
- [x] 6.2 邀请所有 Agent 账户到 agents 房间
- [x] 6.3 验证 Claw Team 主房间包含所有用户和 Agent
- [x] 6.4 文档化 Matrix room 配置
