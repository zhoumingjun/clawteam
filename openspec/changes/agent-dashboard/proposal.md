## Why

当前 Agent 配置（SOUL.md、IDENTITY.md 等）和团队信息（TEAM.md）只能通过文件系统查看和编辑，缺乏可视化界面。需要一个 Web Dashboard 作为 AI Software Factory 的第一个界面入口，先展示 Agent 和团队信息，后续逐步扩展任务、工作流等功能。

## What Changes

- **新建 `dashboard/` 目录**：Next.js 全栈应用（前端 + API Routes 后端）
- **API Routes**：读取 `config/agents/` 目录下所有 Agent 的 Markdown 文件和 `TEAM.md`
- **前端页面**：Agent 列表、Agent 详情/编辑、团队信息查看/编辑
- **Docker 集成**：新增 dashboard 容器加入 docker-compose

## Capabilities

### New Capabilities

- `agent-viewer`: 展示所有 Agent 列表（名称、Emoji、角色、Vibe），点击查看每个 Agent 的完整配置文件（SOUL/IDENTITY/AGENTS/HEARTBEAT/TOOLS/USER/MEMORY/BOOTSTRAP）
- `agent-editor`: 在 Web 界面编辑 Agent 的各个 Markdown 配置文件，保存后写回磁盘
- `team-editor`: 查看和编辑共享的 TEAM.md 团队信息

### Modified Capabilities

（无）

## Impact

- **新增目录**: `dashboard/`（Next.js 项目）
- **新增容器**: dashboard 加入 `containers/docker-compose.yml`
- **依赖**: Node 22+、Next.js 15、React 19
- **挂载**: dashboard 容器需要挂载 `config/agents/` 目录（读写）
- **端口**: dashboard 服务暴露 3000 端口
