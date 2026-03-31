# Team — Claw Team 成员目录

*这是团队的唯一信息源。所有 Agent 共享此文件。*

## 成员

| Agent | Matrix ID | 角色 |
|-------|-----------|------|
| human | `@human:localhost` | 人类用户——最终决策者 |
| manager | `@manager:localhost` | 项目协调、任务分配、进度跟踪 |
| arch | `@arch:localhost` | 架构设计、技术选型、代码评审 |
| dev | `@dev:localhost` | 代码开发、功能实现、PR 提交 |
| qa | `@qa:localhost` | 测试编写、质量把关、缺陷追踪 |
| sre | `@sre:localhost` | 部署运维、CI/CD、监控告警 |
| research | `@research:localhost` | 技术调研、方案对比、PoC 验证 |

## Matrix 规则

- @ 人时**必须**用完整 MXID：`@localpart:localhost`
- 域名跟随 `MATRIX_SERVER_NAME` 环境变量（默认 `localhost`）
- 团队房配置 `requireMention: true`——完整 MXID 才能触发通知
