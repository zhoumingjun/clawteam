# Claw Team 项目追踪器

> 由 sub-agent clawteam-monitor 维护
> 最后更新：2026-03-30 08:21

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

### SPEC-004: storage-volumes ✅
- **提交**: f32205c

### SPEC-005~010: Agent 配置（6个Agent） ✅
- Manager: 2d9d255 | Arch: fe366ef | Dev/QA/SRE/Research: a683ed2
- **安全修复**: fac2260（移除硬编码密码、禁用注册）

### SPEC-011~015 ✅
- SPEC-011: 7d5b0df | SPEC-012: 6a36067 | SPEC-013: 16f8ce6 | SPEC-014: 49d2a51 | SPEC-015: 9621372

### SPEC-016: Element Web UI 集成 ✅
- **提交**: 6c9685b
- **完成时间**: 2026-03-30 08:20
- **验证**: Element Web 正确指向 localhost:8008，端口 10001 可访问

### SPEC-017: 端口安全加固 ✅
- **提交**: [pending push]
- **完成时间**: 2026-03-30 08:21
- **内容**: docker-compose.yml 绑定 127.0.0.1，docs/security.md 安全文档
- **用户初始化**: manager, arch, dev, qa, sre, research, human 全部创建成功

### SPEC-018: OpenClaw Agent Manager 集成 ✅
- **状态**: 已完成
- **完成时间**: 2026-03-30 08:37
- **内容**:
  - docker-compose.yml 添加 openclaw-agent-manager 服务
  - 使用镜像 `ghcr.io/openclaw/openclaw:main-slim`
  - 配置 MATRIX_HOMESERVER, AGENT_ID, AGENT_PASSWORD, OPENCLAW_API_KEY
  - volume 挂载 configs/agents/manager/:/app/agent
  - 网络使用 clawteam-network
  - 依赖 Synapse health check
- **验证**: 服务 healthy ✅

### ✅ MVP + Agent Manager 完成！

## 当前状态
- Synapse ✅ (端口 127.0.0.1:8008)
- Element Web ✅ (端口 127.0.0.1:10001)
- OpenClaw Agent Manager ✅ (服务 healthy)
- 所有用户已初始化 ✅

---

## 任务队列

| 序号 | 任务 | 状态 | 备注 |
|------|------|------|------|
| 1 | SPEC-001: init-project | ✅ 已完成 | 创建目录结构、Makefile、.env.example |
| 2 | SPEC-002: docker-compose | ✅ 已完成 | d276f8f |
| 3 | SPEC-003: conduit-matrix | ✅ 已完成 | ab561cc |
| 4 | SPEC-004: storage-volumes | ✅ 已完成 | f32205c |
| 5 | SPEC-005~010: Agent configs | ✅ 已完成 | 3 commits |
| 6 | SPEC-011: human-agent-protocol | ✅ 已完成 | 7d5b0df |
| 7 | SPEC-012: deployment-guide | ✅ 已完成 | 6a36067 |
| 8 | SPEC-013: smoke-tests | ✅ 已完成 | 16f8ce6 |
| 9 | SPEC-014: e2e-tests | ✅ 已完成 | 49d2a51 |
| 10 | SPEC-015: demo-project | ✅ 已完成 | 9621372 |

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

### 2026-03-30 02:28
- **SPEC-001~SPEC-015 全部完成！**
- sub-agent 监控并推动 Claude Code 持续执行，所有 15 个 SPEC 均已创建并推送
- 总计 16 个 commits（含初始 overview 和 execution plan）

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

~~SPEC-002（docker-compose）、SPEC-003（conduit-matrix）存在严重问题，需重构：~~
~~1. 密码硬编码~~ ✅ 已移除（fac2260）
~~2. API 不兼容（Synapse vs Conduit）~~ ✅ 已切换 Synapse 并修复
~~3. 缺少 Element Web 服务~~ ⚠️ 待补充
~~4. 端口暴露未加固~~ ⚠️ 待补充
~~Synapse Exit(2)~~ ✅ 已修复（94fe00e）

**当前阻塞：**
- Element Web UI 服务未集成
- 端口暴露安全加固待完成

## 进展日志

### 2026-03-30 07:30
- **Synapse 配置修复完成**（commit 94fe00e）：
  - 创建 `configs/synapse/homeserver.yaml`（替代环境变量配置）
  - 修复 YAML 缩进错误（pepper/ACME）
  - 修复 `contexts` → `names`（Synapse API 变更）
  - 添加 `media_store_path` 绝对路径
  - 启用 `enable_registration_without_verification`
  - docker-compose.yml 改用直接 bind mount
  - ✅ API 验证通过（r0.0.1 ~ v1.11）
- **当前状态：** Synapse 运行中，等待下一步指令

## 协作约定

- 灵犀（我）↔ Claude Code：技术讨论伙伴
- 我负责监控、讨论、推动、审阅
- 重大决策（架构方向）需通知用户
- 每30分钟向用户同步进展（飞书）
- 5分钟无响应 → 自行与 Claude Code 讨论决定

### 2026-03-30 06:55 - Synapse 启动修复
**问题：** Synapse Exit(2)，配置挂载与数据卷冲突 + 多处配置错误

**修复内容：**
1. `pepper:` 缩进错误（1空格→2空格）
2. `ACME:` 缩进错误（1空格→0空格）
3. `contexts` → `names`（Synapse API 变更）
4. 添加 `media_store_path: "/data/media_store"`（绝对路径）
5. 添加 `enable_registration_without_verification: true`
6. docker-compose.yml 改用直接 bind mount（`./volumes/synapse-data:/data:rw`）替代 named volume + driver_opts

**结果：** ✅ Synapse healthy，API 正常响应（r0.0.1 ~ v1.11）
