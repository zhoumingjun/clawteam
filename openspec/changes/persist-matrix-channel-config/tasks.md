## 1. 配置目录准备

- [ ] 1.1 创建 `configs/agents/manager/openclaw.json` 配置文件
- [ ] 1.2 验证配置文件格式正确

## 2. 初始化脚本创建

- [ ] 2.1 创建 `scripts/openclaw-matrix-init.sh`
- [ ] 2.2 实现 matrix 插件启用
- [ ] 2.3 实现 allowPrivateNetwork 配置
- [ ] 2.4 实现 channel 添加（不包含密码）
- [ ] 2.5 实现连接状态验证

## 3. Docker Compose 更新

- [ ] 3.1 更新 volume 挂载，添加 openclaw.json
- [ ] 3.2 添加 environment 变量用于密码注入
- [ ] 3.3 添加 OPENCLAW_AGENT_PASSWORD 环境变量

## 4. 测试验证

- [ ] 4.1 重启容器验证配置持久化
- [ ] 4.2 验证 Matrix channel 状态
- [ ] 4.3 更新 TRACKER.md
