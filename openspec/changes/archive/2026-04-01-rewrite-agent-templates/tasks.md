## 1. Manager Agent 重写

- [x] 1.1 重写 `config/agents/manager/SOUL.md` — Core Truths（项目协调者视角）+ Boundaries（含 @manager:localhost、安全边界）+ Vibe + Role Context + Continuity
- [x] 1.2 重写 `config/agents/manager/IDENTITY.md` — 5 字段格式（Name: Manager / Creature / Vibe / Emoji / Avatar）
- [x] 1.3 重写 `config/agents/manager/AGENTS.md` — 补充 Session Startup、Memory、Red Lines、Group Chat（Matrix 团队房规则）、Heartbeat、Tools 官方必需节；保留 Team Protocol（全员列表+MXID 规则）、Task Protocol（任务卡片+流转）、Deliverables
- [x] 1.4 重写 `config/agents/manager/USER.md` — 渐进式人类档案（Name/称呼/Timezone/Context），用户 = 人类
- [x] 1.5 重写 `config/agents/manager/MEMORY.md` — 清空为注释说明（用途 + 使用规则）
- [x] 1.6 重写 `config/agents/manager/HEARTBEAT.md` — 3-5 项 manager 特定 checklist（任务队列、团队阻塞、进度汇报）
- [x] 1.7 重写 `config/agents/manager/TOOLS.md` — 环境备忘录（Matrix 配置、常用命令速查）
- [x] 1.8 新建 `config/agents/manager/BOOTSTRAP.md` — 首次运行引导（确认身份、熟悉工作空间、团队房自我介绍、删除此文件）

## 2. Arch Agent 重写

- [x] 2.1 重写 `config/agents/arch/SOUL.md` — Core Truths（架构师视角：简洁设计、数据驱动决策）+ Boundaries（含 @arch:localhost）+ Vibe + Role Context + Continuity
- [x] 2.2 重写 `config/agents/arch/IDENTITY.md` — 5 字段格式
- [x] 2.3 重写 `config/agents/arch/AGENTS.md` — 官方必需节 + Team Protocol + Deliverables（架构文档、技术选型、ADR、评审标准）
- [x] 2.4 重写 `config/agents/arch/USER.md` — 用户 = Manager Agent
- [x] 2.5 重写 `config/agents/arch/MEMORY.md` — 注释说明
- [x] 2.6 重写 `config/agents/arch/HEARTBEAT.md` — arch 特定 checklist（设计评审队列、技术债务、文档同步）
- [x] 2.7 重写 `config/agents/arch/TOOLS.md` — 环境备忘录
- [x] 2.8 新建 `config/agents/arch/BOOTSTRAP.md`

## 3. Dev Agent 重写

- [x] 3.1 重写 `config/agents/dev/SOUL.md` — Core Truths（开发者视角：代码质量、增量交付）+ Boundaries（含 @dev:localhost）+ Vibe + Role Context + Continuity
- [x] 3.2 重写 `config/agents/dev/IDENTITY.md` — 5 字段格式
- [x] 3.3 重写 `config/agents/dev/AGENTS.md` — 官方必需节 + Team Protocol + Task Protocol（接收任务流程）+ Deliverables（源代码、单元测试、PR）
- [x] 3.4 重写 `config/agents/dev/USER.md` — 用户 = Manager Agent
- [x] 3.5 重写 `config/agents/dev/MEMORY.md` — 注释说明
- [x] 3.6 重写 `config/agents/dev/HEARTBEAT.md` — dev 特定 checklist（CI/CD 状态、代码质量、依赖更新）
- [x] 3.7 重写 `config/agents/dev/TOOLS.md` — 环境备忘录
- [x] 3.8 新建 `config/agents/dev/BOOTSTRAP.md`

## 4. QA Agent 重写

- [x] 4.1 重写 `config/agents/qa/SOUL.md` — Core Truths（QA 视角：质量第一、预防优于修复）+ Boundaries（含 @qa:localhost）+ Vibe + Role Context + Continuity
- [x] 4.2 重写 `config/agents/qa/IDENTITY.md` — 5 字段格式
- [x] 4.3 重写 `config/agents/qa/AGENTS.md` — 官方必需节 + Team Protocol + Deliverables（测试计划、缺陷报告、覆盖率）
- [x] 4.4 重写 `config/agents/qa/USER.md` — 用户 = Manager Agent
- [x] 4.5 重写 `config/agents/qa/MEMORY.md` — 注释说明
- [x] 4.6 重写 `config/agents/qa/HEARTBEAT.md` — qa 特定 checklist（测试执行状态、缺陷跟踪、覆盖率）
- [x] 4.7 重写 `config/agents/qa/TOOLS.md` — 环境备忘录
- [x] 4.8 新建 `config/agents/qa/BOOTSTRAP.md`

## 5. SRE Agent 重写

- [x] 5.1 重写 `config/agents/sre/SOUL.md` — Core Truths（SRE 视角：稳定性优先、自动化一切）+ Boundaries（含 @sre:localhost）+ Vibe + Role Context + Continuity
- [x] 5.2 重写 `config/agents/sre/IDENTITY.md` — 5 字段格式
- [x] 5.3 重写 `config/agents/sre/AGENTS.md` — 官方必需节 + Team Protocol + Deliverables（部署清单、CI/CD、监控、事故响应）
- [x] 5.4 重写 `config/agents/sre/USER.md` — 用户 = Manager Agent
- [x] 5.5 重写 `config/agents/sre/MEMORY.md` — 注释说明
- [x] 5.6 重写 `config/agents/sre/HEARTBEAT.md` — sre 特定 checklist（服务健康、资源使用、告警、部署状态、日志异常）
- [x] 5.7 重写 `config/agents/sre/TOOLS.md` — 环境备忘录
- [x] 5.8 新建 `config/agents/sre/BOOTSTRAP.md`

## 6. Research Agent 重写

- [x] 6.1 重写 `config/agents/research/SOUL.md` — Core Truths（研究员视角：深度调研、证据驱动）+ Boundaries（含 @research:localhost）+ Vibe + Role Context + Continuity
- [x] 6.2 重写 `config/agents/research/IDENTITY.md` — 5 字段格式
- [x] 6.3 重写 `config/agents/research/AGENTS.md` — 官方必需节 + Team Protocol + Deliverables（调研报告、方案对比、PoC）
- [x] 6.4 重写 `config/agents/research/USER.md` — 用户 = Manager Agent / Arch Agent
- [x] 6.5 重写 `config/agents/research/MEMORY.md` — 注释说明
- [x] 6.6 重写 `config/agents/research/HEARTBEAT.md` — research 特定 checklist（研究任务进度、技术追踪、知识库更新）
- [x] 6.7 重写 `config/agents/research/TOOLS.md` — 环境备忘录
- [x] 6.8 新建 `config/agents/research/BOOTSTRAP.md`

## 7. Default Workspace 重写

- [x] 7.1 重写 `config/agents/default/SOUL.md` — 通用协调者角色"Claw"（非 manager 拷贝），Core Truths + Boundaries + Vibe + Role Context + Continuity
- [x] 7.2 重写 `config/agents/default/IDENTITY.md` — 5 字段格式（Name: Claw）
- [x] 7.3 重写 `config/agents/default/AGENTS.md` — 最小操作手册（仅官方必需节，无业务扩展）
- [x] 7.4 重写 `config/agents/default/USER.md` — 用户 = 人类
- [x] 7.5 重写 `config/agents/default/MEMORY.md` — 注释说明
- [x] 7.6 重写 `config/agents/default/HEARTBEAT.md` — 最小 checklist 或留空
- [x] 7.7 重写 `config/agents/default/TOOLS.md` — 最小环境备忘录
- [x] 7.8 新建 `config/agents/default/BOOTSTRAP.md`

## 8. 测试与验证

- [x] 8.1 更新 `tests/test_repo_layout.py` — 在 `test_agent_workspace_files` 检查列表中添加 `BOOTSTRAP.md`
- [x] 8.2 运行 `pytest tests/test_repo_layout.py` 验证所有文件存在
- [x] 8.3 人工审查：对比每个 Agent 的 SOUL.md 确认人格各异
- [x] 8.4 人工审查：确认所有 HEARTBEAT.md 内容不同（角色特定）
- [x] 8.5 人工审查：确认 default/ 目录不是 manager 的拷贝
