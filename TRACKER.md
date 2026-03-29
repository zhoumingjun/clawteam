# Claw Team 项目追踪器

> 由 sub-agent clawteam-monitor 维护
> 最后更新：2026-03-30 02:21

---

## 项目状态

| 项目 | 值 |
|------|-----|
| GitHub | https://github.com/zhoumingjun/clawteam |
| 当前分支 | main |
| tmux session | clawteam |

---

## 执行计划

### SPEC-001: init-project ✅
- **状态**: 已完成
- **负责人**: Claude Code
- **目标**: 建立项目基础结构
- **交付物**: 目录结构、Makefile、.env.example、.gitignore
- **提交**: d25a8de - feat: init project structure with Makefile, .env.example, .gitignore
- **完成时间**: 2026-03-30 02:22

### SPEC-002: docker-compose ✅
- **状态**: 已完成
- **提交**: d276f8f
- **完成时间**: 2026-03-30 02:23

### SPEC-003: conduit-matrix ✅
- **状态**: 已完成
- **提交**: ab561cc
- **完成时间**: 2026-03-30 02:25

### SPEC-004 ~ SPEC-015（待执行）
按 `docs/execution-plan.md` 执行

---

## 任务队列

| 序号 | 任务 | 状态 | 备注 |
|------|------|------|------|
| 1 | SPEC-001: init-project | ✅ 已完成 | 创建目录结构、Makefile、.env.example |
| 2 | SPEC-002: docker-compose | ✅ 已完成 | d276f8f |
| 3 | SPEC-003: conduit-matrix | ✅ 已完成 | ab561cc |
| 4 | SPEC-004: storage-volumes | ✅ 已完成 | f32205c |
| 5 | SPEC-005: agent-config-manager | 待执行 | 依赖 SPEC-002 |

---

## 当前指令

当 Claude Code 空闲时，发送：
```
请执行 SPEC-001 init-project：
1. 创建目录结构（configs/agents/{manager,arch,dev,qa,sre,research}, configs/matrix, volumes/{openclaw-config,openclaw-data,conduit-data}, tests/{smoke,e2e}）
2. 创建 Makefile（包含 build, up, down, logs, test-smoke, test-e2e 等目标）
3. 创建 .env.example（包含必要的环境变量模板）
4. 创建 .gitignore（包含 .env, volumes/, .DS_Store 等）
5. 提交并推送
```

---

## 进展日志

### 2026-03-30 02:21
- 项目初始化完成（overview.md, execution-plan.md）
- CLAUDE.md 已配置
- 灵犀已接入，持续监控机制建立

---

## OpenSpec 流程

```
1. Claude Code 提出 SPEC 提案
2. 灵犀审阅（技术可行性、完整性、合理性）
3. 如有问题 → 讨论修改
4. 确认无误 → apply 执行
```

**重要：每个 SPEC 在 apply 前必须经过灵犀审阅**

## 审阅标准

每个任务必须参考业界最佳实践：

| 领域 | 参考标准 |
|------|----------|
| Docker Compose | 官方最佳实践、healthcheck、depends_on + condition |
| Matrix | Conduit vs Synapse API 能力对比 |
| Shell 脚本 | set -euo pipefail、shellcheck |
| 架构 | 12-Factor App 原则 |
| 安全 | CIS Docker Benchmark、OWASP Top 10 |
| 备份 | 3-2-1 原则 |

## 当前阻塞

SPEC-002（docker-compose）、SPEC-003（conduit-matrix）存在严重问题，需重构：
1. 密码硬编码
2. API 不兼容（Synapse vs Conduit）
3. 缺少 Element Web 服务
4. 端口暴露未加固

## 协作约定

- 灵犀（我）↔ Claude Code：技术讨论伙伴
- 我负责监控、讨论、推动、审阅
- 重大决策（架构方向）需通知用户
- 每30分钟向用户同步进展（飞书）
- 5分钟无响应 → 自行与 Claude Code 讨论决定
