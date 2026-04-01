## Context

ClawTeam 是一个基于 OpenClaw + Matrix 协议的多 agent 软件工厂。当前进部署架构存在以下问题：

- `configs/agents/` 通过 volume 挂载注入，不进镜像——违背不可变基础设施原则
- 用户需输入 7 个密码（6 agent + 1 human），agent 密码仅用于注册拿 token
- 启动依赖 3 个分散脚本（`init.sh`、`openclaw-agent-init.sh`、`openclaw-matrix-init.sh`）
- 遗留文件（Conduit 配置）和命名不一致（`sould.md`）造成混乱

## Goals / Non-Goals

**Goals:**
- Agent config 进镜像（只读），`~/.openclaw/` 做 volume 持久化（读写）
- 用户输入精简为：model provider + human 密码（+ server name 默认值）
- 启动流程合并为单一 `openclaw-startup.sh`
- 清理所有遗留文件和命名不一致问题

**Non-Goals:**
- 不改变 agent 间的通信方式（保持 Matrix 协议）
- 不拆分为多容器（共用一个 openclaw 容器）
- 不引入新的外部依赖（当前技术栈不变）

## Decisions

### Decision 1: Volume 策略——镜像 + volume 混合

**选择**：Agent config（`configs/agents/`）打包进 Dockerfile；`~/.openclaw/` 目录 volume 持久化。

**替代方案 A**：全 volume 挂载（当前方案）。镜像仅包含 base image，所有配置运行时注入。缺点：镜像不可复现，配置分散。

**替代方案 B**：全镜像（无 volume）。所有内容进镜像。缺点：重建镜像 = 丢失 agent state（凭据、会话、memory），不可接受。

**理由**：`~/.openclaw/` volume 包含凭据、会话、memory 等动态 state，必须持久化；agent config 是只读静态配置，适合打包进镜像。

### Decision 2: Agent 密码——启动时随机生成

**选择**：Agent 密码在 `openclaw-startup.sh` 中用 `openssl rand -hex 16` 随机生成，写入 `~/.openclaw/.agent-passwords` 文件。

**替代方案**：统一默认密码。缺点：不安全，且用户无法通过 Element Web 访问 agent 账号（agent 不需要 UI 访问）。

**理由**：Agent 仅需要 Matrix token 与 Synapse 通信，不需要 human 交互，密码随机生成无 UX 影响。Human 密码由用户手动提供（需在 Element Web 登录）。

### Decision 3: Startup 流程——三合一脚本

**选择**：删除 `configs/matrix/init.sh`、`openclaw-agent-init.sh`、`openclaw-matrix-init.sh`，合并为单一的 `openclaw-startup.sh`。

**替代方案**：保留多脚本，入口脚本统一调用。缺点：增加复杂度，多个环境变量传递点。

**理由**：当前三个脚本各自承担部分职责，职责边界不清晰。合并后逻辑内聚，便于维护。

### Decision 4: Agent 配置文件名——`sould.md` → `SOUL.md`

**选择**：将所有 agent 目录下的 `sould.md` 重命名为 `SOUL.md`。

**替代方案**：保持小写。缺点：与 OpenClaw 约定不一致，可能导致功能问题（如 mention、heartbeat 等）。

**理由**：OpenClaw 对配置文件名有大小写约定，保持 `SOUL.md`、`AGENTS.md`、`HEARTBEAT.md` 等标准命名避免潜在兼容性问题。

### Decision 5: openclaw.json 动态生成

**选择**：`openclaw.json` 完全由 `openclaw-startup.sh` 生成，不在版本控制中。

**替代方案**：版本控制 `openclaw.json`。缺点：包含动态数据（room ID、token、bindings），每次启动都需 diff/merge。

**理由**：`openclaw.json` 的 `bindings` 包含动态 room ID，`credentials` 包含 token，均为运行时生成。版本控制会导致每次启动产生 diff。

## Risks / Trade-offs

- **风险**：首次启动后 volume 中有 state，后续修改 agent config 需要清理 volume 才生效。
  - **缓解**：文档说明 agent config 变更需 `docker compose down -v` 清理 volume。

- **风险**：随机密码生成依赖 `/dev/urandom`，容器环境中可用。
  - **缓解**：使用 `openssl rand -hex 16`，无需额外依赖。

- **风险**：合并 startup 脚本后，如果失败重试逻辑不够健壮会遗留脏 state。
  - **缓解**：脚本设计幂等（check before action），注册前先检查用户是否已存在。

- **风险**：删除 `openclaw.json` 版本控制后，团队成员无法审查路由配置。
  - **缓解**：在 `openclaw-startup.sh` 中将生成的配置输出到日志，并在成功后打印关键配置项。

## Migration Plan

1. **备份**：`docker compose down`，备份 `volumes/openclaw-data/` 目录
2. **更新文件**：应用所有代码变更（Dockerfile、docker-compose、startup 脚本、agent configs）
3. **重建镜像**：`docker compose build`
4. **更新 .env**：用户提供新的环境变量（MODEL_PROVIDER、HUMAN_PASSWORD）
5. **启动**：`docker compose up -d`，观察 `docker compose logs -f openclaw`
6. **验证**：`openclaw health` 确认 gateway 就绪，Element Web 登录 human 账号

**回滚**：恢复 `volumes/openclaw-data/` 备份，恢复原 `docker-compose.yml`、`Dockerfile.openclaw`、`openclaw-startup.sh`，重启即可。

## Open Questions

1. **Room ID 动态发现**：当前硬编码 `!JnzzKhxMVRCvoDRUmw:localhost`，是否需要在 startup 时动态发现或创建 Matrix room？
2. **Model provider 配置**：通过环境变量 `MODEL_PROVIDER` 传入后，OpenClaw 如何读取并配置？需要确认 openclaw 的 model 配置格式。
3. **TRACKER.md 更新频率**：重构完成后 SPEC-026 状态是"进行中"还是直接标记"完成"？
