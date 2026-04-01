## Why

当前部署流程存在三个核心问题：(1) `configs/agents/` 以 volume 挂载方式运行时注入，不进镜像，违背"不可变基础设施"原则；(2) 用户需输入 7 个密码（6 agent + 1 human），负担过重且 agent 密码仅用于注册拿 token；(3) 多处遗留文件（Conduit 配置、HEARTBEAT.md 引用、stale room ID）和不一致命名（sould.md vs SOUL.md）造成混乱。重构旨在简化部署流程、减少用户输入、清理遗留文件。

## What Changes

- **Dockerfile.openclaw**：将 `configs/agents/` COPY 进镜像，镜像包含完整 agent 配置，运行时通过 `~/.openclaw/` volume 持久化动态 state
- **docker-compose.yml**：将 `openclaw-data` volume 改为完整挂载 `~/.openclaw/` 目录；移除 `configs/agents` 的 volume 挂载
- **`.env` 文件简化**：用户只需提供 `MODEL_PROVIDER`、`HUMAN_PASSWORD`、`SYNAPSE_SERVER_NAME`，其余自动生成
- **Startup 脚本重构** (`openclaw-startup.sh`)：自动完成 agent 密码随机生成 → 调用 Synapse Admin API 注册 → 获取 access_token → 生成 `openclaw.json` → 注册 agent workspace；完全替代 `configs/matrix/init.sh`、`openclaw-agent-init.sh`、`openclaw-matrix-init.sh` 三个脚本
- **清理遗留文件**：删除 `configs/matrix/conduit.yaml`；删除所有 `HEARTBEAT.md` 文件引用；`configs/agents/` 中的 `openclaw.json` 文件（动态生成，不再版本控制）
- **文档更新**：同步更新 `README.md`、`deployment-guide.md`、`CLAUDE.md` 中的过时 Conduit 引用；TRACKER.md 新增 SPEC-026
- **Agent 配置文件名统一**：将 `sould.md` 重命名为 `SOUL.md`（OpenClaw 约定大小写）

## Capabilities

### New Capabilities

- `deployment-init`: 启动时自动初始化能力。包含：随机生成 agent 密码、调用 Synapse Admin API 完成 Matrix 用户注册、获取 access_token 并持久化、生成 openclaw.json（包含 bindings + mentionPatterns）、注册所有 agent workspace 到 OpenClaw Gateway。
- `volume-strategy`: 统一 volume 策略。Agent config 进镜像（只读），`~/.openclaw/` 挂载 volume（读写，包含所有运行时 state）。

### Modified Capabilities

- `agent-config`: Agent 配置文件名从 `sould.md` 改为 `SOUL.md`（遵循 OpenClaw 大小写约定），`openclaw.json` 从版本控制中移除（动态生成）。

## Impact

- **Dockerfile**：新增 `COPY configs/agents/ /app/agents/`
- **docker-compose.yml**：volume 配置变更，`openclaw-data` → `openclaw`
- **Startup 流程**：从 3 个脚本合并为 1 个 `openclaw-startup.sh`
- **.env**：移除 6 个 agent 密码环境变量，仅保留 `HUMAN_PASSWORD`
- **Agent configs**：所有 agent 目录下的 `sould.md` 重命名为 `SOUL.md`；删除 `openclaw.json`
- **文档**：README、deployment-guide、CLAUDE.md 更新；TRACKER.md 新增 SPEC-026
