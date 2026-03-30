# Claw Team 项目追踪器

> 由 灵犀 维护
> 最后更新：2026-03-30 11:53

---

## 项目状态

| 项目 | 值 |
|------|-----|
| GitHub | https://github.com/zhoumingjun/clawteam |
| 当前分支 | main |
| tmux session | clawteam |

---

## SPEC 执行计划（全部完成 ✅）

| SPEC | 名称 | 提交 | 完成时间 |
|------|------|------|----------|
| 001 | init-project | d25a8de | 02:22 |
| 002 | docker-compose | d276f8f | 02:23 |
| 003 | conduit-matrix | ab561cc | 02:25 |
| 004 | storage-volumes | f32205c | 02:25 |
| 005~010 | Agent configs（6个） | 2d9d255, fe366ef, a683ed2, fac2260 | 02:28 |
| 011 | human-agent-protocol | 7d5b0df | 02:28 |
| 012 | deployment-guide | 6a36067 | 02:28 |
| 013 | smoke-tests | 16f8ce6 | 02:28 |
| 014 | e2e-tests | 49d2a51 | 02:28 |
| 015 | demo-project | 9621372 | 02:28 |
| 016 | Element Web UI 集成 | 6c9685b | 08:20 |
| 017 | 端口安全加固 | f2e9cfc | 08:21 |
| 018 | OpenClaw Agent Manager 集成 | f175d3a, 099cef1 | 08:40 |
| 019 | OpenClaw Agent Matrix 连接 | 015b808, 76d8141 | 09:04 |
| 020 | Matrix channel 配置持久化 | 83d764c | 09:17 |
| 021 | 多 Agent 协作测试 | 5b2fa27 | 09:25 |
| 022 | Dev Agent 部署 | — | 09:30 |
| 023 | Matrix 房间配置 | eca996f | 11:37 |

---

## 服务状态（2026-03-30 11:46）

| 服务 | 状态 | 端口 |
|------|------|------|
| Synapse (Matrix HS) | ✅ healthy | 127.0.0.1:8008 |
| Element Web | ✅ healthy | 127.0.0.1:10001 |
| OpenClaw Agent Manager | ✅ healthy | container |
| OpenClaw Agent Dev | ✅ healthy | container |

---

## 重要架构发现

OpenClaw Agent 是 **Gateway-first** 架构，不是传统 Matrix bot：
- Matrix channel 用于**发送通知**
- 指令通过 **Gateway RPC** 接收（`openclaw agent` 命令显式调用）
- Session 管理是显式的，不自动响应 @mention

---

## 待主公裁决：架构方向

| 方案 | 描述 | 推荐 |
|------|------|------|
| A: Gateway-first | Human → Gateway API → Agent → Matrix 通知 | ✅ 推荐 |
| B: Matrix bot 改造 | 引入 mautrix/matrix-bot-sdk，实现真正 bot 行为 | 待裁决 |

---

## 错误记录

### 10:36 - 主机 openclaw CLI 依赖缺失
- **问题**: Claude Code 在主机 macOS 运行 `openclaw channels add`
- **根因**: 主机 OpenClaw CLI 缺少 `@vector-im/matrix-bot-sdk`，且 `mkdir '/openclaw'` 指向根目录
- **修复**: 更新 `CLAUDE.md`，禁止主机运行 openclaw CLI，所有操作必须在 Docker 容器内执行

### 09:26 - Claude Code 幻觉事件
- 伪造"主公已裁决"消息，已纠正

### 06:55 - Synapse Exit(2)
- homeserver.yaml 缩进错误 + contexts→names API 变更
- 修复：94fe00e，API 验证通过

---

## 协作约定

- 灵犀（我）↔ Claude Code：技术讨论伙伴
- 重大决策（架构方向）需通知主公
- 每30分钟向主公同步进展（飞书）
- 5分钟无响应 → 自行与 Claude Code 讨论决定

---

## OpenSpec 流程

```
1. Claude Code 提出 SPEC 提案
2. 灵犀审阅（技术可行性、完整性、合理性）
3. 如有问题 → 讨论修改
4. 确认无误 → apply 执行
```

**重要：每个 SPEC 在 apply 前必须经过灵犀审阅**

---

## 审阅标准

| 领域 | 参考标准 |
|------|----------|
| Docker Compose | 官方最佳实践、healthcheck、depends_on + condition |
| Shell 脚本 | set -euo pipefail、shellcheck |
| 架构 | 12-Factor App 原则 |
| 安全 | CIS Docker Benchmark、OWASP Top 10 |
