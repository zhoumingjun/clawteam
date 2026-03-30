## 1. Agent 用户准备

- [ ] 1.1 在 Synapse 注册 `openclaw-agent` 用户
- [ ] 1.2 设置用户密码并记录

## 2. Matrix 插件配置

- [ ] 2.1 启用 matrix 插件 (`openclaw plugins enable matrix`)
- [ ] 2.2 设置 `allowPrivateNetwork: true`
- [ ] 2.3 添加 Matrix channel 配置（homeserver, user-id, password）
- [ ] 2.4 重启容器

## 3. 验证测试

- [ ] 3.1 检查 `openclaw channels status` 显示 running
- [ ] 3.2 在 Element Web 创建测试 room
- [ ] 3.3 邀请 Agent 用户到 room
- [ ] 3.4 发送测试消息验证响应

## 4. 自动化脚本

- [ ] 4.1 创建 `tests/matrix-connection-test.sh`
- [ ] 4.2 脚本实现：创建 room、发送消息、验证响应
- [ ] 4.3 集成到 Makefile test-smoke

## 5. Docker Compose 更新

- [ ] 5.1 添加初始化脚本自动配置 Matrix 插件
- [ ] 5.2 确保容器启动时自动启用 Matrix channel
