## Why

当前 Claw Team 的 6 个 AI Agent 通过 Matrix 协作，但缺乏结构化的任务管理、工作流引擎和可视化界面。任务靠 Manager 在聊天里人肉派发文本卡片，没有状态机、没有持久化、无法追溯；代码交付靠手动操作 Git，没有自动 branch/MR/review 流程。要从"AI 聊天团队"进化到"AI 软件工厂"，需要补齐这三块基础设施。

## What Changes

- **新增 Go 后端服务**（Factory Server）：任务管理 + 工作流引擎 + Git 集成 + REST API
- **新增 Next.js Web Dashboard**：Agent 状态、项目/任务进度、聊天历史、工作流可视化
- **新增 SQLite 数据库**：任务、工作流实例、Git 操作记录、聊天历史持久化
- **新增 Git Provider 抽象层**：同时支持 GitLab 和 GitHub（branch/commit/MR/review）
- **新增两个预置工作流**：Feature 开发流程、Bug Fix 流程
- **扩展现有 Agent 协议**：Agent 输出结构化 JSON，支持 workflow 回调

## Capabilities

### New Capabilities

- `task-management`: 任务 CRUD、DAG 依赖关系、状态机流转、关联 spec/MR/agent
- `workflow-engine`: 工作流定义（YAML）、状态机驱动、agent 调度、支持 feature-dev 和 bug-fix 两种预置流程
- `git-provider`: Git 平台抽象接口（GitLab + GitHub adapter），自动 branch/commit/MR/review comment
- `web-dashboard`: Web UI 查看 agent 状态、项目任务进度、聊天历史、工作流执行情况
- `factory-api`: REST API 服务，连接前端、工作流引擎、Agent（通过 Matrix）、Git 平台

### Modified Capabilities

（无现有 spec 需要修改）

## Impact

- **新增目录**: `factory/`（Go 后端）、`web/`（Next.js 前端）
- **新增容器**: factory-server、web-dashboard 加入 docker-compose
- **数据库**: SQLite 文件存储在 `volumes/factory/factory.db`
- **依赖**: Go 1.22+、Node 22+、Matrix SDK (Go)、GitLab/GitHub API SDK
- **现有 Agent**: 需要扩展输出协议（结构化 JSON），AGENTS.md 增加 workflow 交互规则
- **部署**: docker-compose 从 2 容器扩展到 4 容器
