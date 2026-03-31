## Context

Claw Team 有 6 个 AI Agent 运行在 OpenClaw 容器内。配置文件存储在 `volumes/openclaw/{agent}/` 运行时目录（从 `config/agents/` 模板首次启动时拷贝）。当前只能通过文件系统或 CLI 查看。

**架构约束**：`config/agents/` 是不可变模板（Git 跟踪），`volumes/openclaw/` 是运行时可变数据。Dashboard 只读写 volumes。

## Goals / Non-Goals

**Goals:**
- 在 `dashboard/` 构建 Next.js 全栈应用，展示和编辑 Agent 配置与团队信息
- 通过 Docker 容器部署，挂载 `volumes/openclaw/` 读写运行时数据
- 作为 AI Software Factory 的第一个 Web 界面入口

**Non-Goals:**
- 不做任务管理、工作流引擎（后续迭代）
- 不做聊天历史展示（后续迭代）
- 不做用户认证

## Decisions

### 1. 数据来源：直接读写 volumes 目录
Dashboard 容器挂载 `volumes/openclaw/` 读写 workspace 文件。不通过 OpenClaw CLI/API 中转——文件系统直接操作最简单可靠。

### 2. Next.js API Routes 作后端
无需独立 Go 后端。API Routes 通过 `fs` 模块读写文件，环境变量 `OPENCLAW_DATA_DIR` 控制挂载路径。

### 3. TEAM.md 运行时化
修改 `agents-init.sh`，启动时将 `config/agents/TEAM.md` 拷贝到 `volumes/openclaw/TEAM.md`（仅首次）。Dashboard 读写运行时副本。

### 4. 纯文本编辑 Markdown
使用 textarea 编辑 Markdown 源码，不做富文本。Agent 配置文件本质上是给 LLM 读的。

## Risks / Trade-offs

- [并发编辑] → 单用户场景无风险，后续可加文件锁
- [volumes 目录不存在] → 需要先 `make fresh` 部署才能使用 dashboard
