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

### SPEC-001: init-project（进行中）
- **状态**: 待执行
- **负责人**: Claude Code
- **目标**: 建立项目基础结构
- **交付物**: 目录结构、Makefile、.env.example
- **依赖**: 无

### SPEC-002 ~ SPEC-015（待执行）
按 `docs/execution-plan.md` 执行

---

## 任务队列

| 序号 | 任务 | 状态 | 备注 |
|------|------|------|------|
| 1 | SPEC-001: init-project | 待执行 | 创建目录结构、Makefile、.env.example |
| 2 | SPEC-002: docker-compose | 待执行 | 依赖 SPEC-001 |
| 3 | SPEC-003: conduit-matrix | 待执行 | 依赖 SPEC-001 |
| 4 | SPEC-004: storage-volumes | 待执行 | 依赖 SPEC-001 |

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

## 协作约定

- 灵犀（我）↔ Claude Code：技术讨论伙伴
- 我负责监控、讨论、推动
- 重大决策（架构方向）需通知用户
- 每30分钟向用户同步进展（飞书）
