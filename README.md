# Claw Team

**开箱即用的 AI 软件研发工厂（MVP）**

多个专业化 Agent（Manager、Arch、Dev、QA、SRE、Research）通过 **Matrix（[Tuwunel](https://github.com/matrix-construct/tuwunel)）** 与人、彼此之间协作；运行时由 **OpenClaw Gateway** 统一管理。

## 推荐目录结构（MVP）

约定：**可编辑的配置与不可变部署产物分离**，数据进 `volumes/`，避免根目录堆叠多套 compose。

| 路径 | 用途 |
|------|------|
| `deploy/` | **唯一** Docker 编排：`docker-compose.yml`、各 `Dockerfile`、`homeserver.yaml` |
| `config/openclaw/` | 各 Agent 的 Markdown workspace 模板（只读挂载进容器，拷入持久化目录） |
| `volumes/` | Tuwunel（`tuwunel-data`）与 OpenClaw 持久化数据（不入库，`.gitignore`） |
| `matrix/` | **Matrix 团队协作**：账号密码同步、团队房 bootstrap、mention 相关 E2E |
| `openclaw/` | **OpenClaw 运行时**：容器入口 `openclaw-startup.sh` |
| `platform/` | **交付与基础设施**：`deploy.sh`、`sync-synapse-config.sh`、卷备份/恢复 |
| `docs/` | 设计与运维文档（**[用户手册](docs/user-manual.md)**、**[开发手测](docs/developer-handbook.md)**） |
| `tests/` | **pytest** 回归（`test_smoke.py` 使用 `@pytest.mark.smoke`） |
| `pyproject.toml`、`uv.lock` | **Python 工具链**（[uv](https://docs.astral.sh/uv/)） |

不再维护重复的 `dist/`、`ops/ci/` 等第二套部署树；定制 Synapse 只改 `deploy/homeserver.yaml`。

## 一键部署（首选：每次干净重来）

开发/验收时建议**每次都清空本地数据再拉栈**，避免旧 Synapse 密码、旧 `openclaw.json` 与 `.agent-tokens` 不一致：

```bash
git clone https://github.com/zhoumingjun/clawteam.git
cd clawteam
cp .env.example .env
# 编辑 .env：至少填写 ANTHROPIC_API_KEY、HUMAN_PASSWORD、各 AGENT *_PASSWORD

make fresh     # 或: ./platform/deploy.sh --fresh
```

`make fresh` / `platform/deploy.sh --fresh` 会：`docker compose down -v`、清空 **`volumes/tuwunel-data`** 与 **`volumes/openclaw`**，再 **先启动 Tuwunel** → 等待 `/_matrix/client/versions` → **`matrix/sync-all-matrix-passwords.sh`**（按 `.env` 注册/登录用户）→ **再启动 OpenClaw**，避免两容器并行导致拿不到 manager token、**不建团队房**。**Homeserver DB 与 OpenClaw 状态在 fresh 时会丢失**。Synapse 数据不可原地迁移至 Tuwunel（见 [tuwunel#2](https://github.com/matrix-construct/tuwunel/issues/2)），请使用干净卷。

若要在**不删数据**的前提下只重启/升级镜像：

```bash
make deploy    # 等同 ./platform/deploy.sh
# 或
make up
```

## 本地测试（不依赖 GitHub）

**前提**：安装 [uv](https://docs.astral.sh/uv/)（管理 Python 3.12 与 dev 依赖）。克隆后可在项目根执行 `uv sync` 创建 `.venv/` 并安装 `pytest`、`httpx` 等。

在项目根目录、已配置 **`.env`** 的前提下：

```bash
# 1. Python 依赖（首次或大改 pyproject/lock 后）
uv sync

# 2. 语法检查（可选，部署相关 Shell）
shellcheck platform/deploy.sh openclaw/openclaw-startup.sh platform/sync-synapse-config.sh tests/e2e/run.sh

# 3. 启动栈（若已在跑可跳过）
./platform/deploy.sh   # 或 make up

# 4. 全部自动化测试（pytest：smoke + Matrix + Docker + 仓库）
make test

# 5. 仅快速烟雾子集（pytest -m smoke）
make test-smoke

# 6. 手写抽查
curl -sS "http://127.0.0.1:${SYNAPSE_PORT:-8008}/_matrix/client/versions" | head
docker compose -f deploy/docker-compose.yml --env-file .env exec openclaw openclaw health || true
```

「能不能真跟 Agent 聊」仍需用 **Element** 连本机 Homeserver 做人工验证（见下节）。

## 使用 Element 与 Agent 对话

1. 打开 Element（或其它 Matrix 客户端），Homeserver 填 **`http://127.0.0.1:8008`**（若修改了 `SYNAPSE_PORT`，以 `.env` 为准）。
2. 使用 **`@human:你的服务器名`** 登录，密码见 `.env` 的 `HUMAN_PASSWORD`。若提示密码错误，多半是首次启动时容器曾用**随机**密码注册过 Human，而 `.env` 是后来才改的——在项目根执行 **`bash matrix/sync-human-matrix-password.sh`** 可把当前 `.env` 中的密码写回 Synapse，然后再登录。
3. 首次启动时，OpenClaw 会尝试用 **manager** 建 **`Claw Team`** 房并邀请 `@human` 与各 agent。若 **Element 里没有任何房间**，常见原因是 Synapse 里的账号密码仍是旧值（与 `.env` 不一致），导致建群/邀请失败。请依次执行：**`bash matrix/sync-all-matrix-passwords.sh`** → **`bash matrix/matrix-bootstrap-team-room.sh`** → **`docker compose -f deploy/docker-compose.yml --env-file .env restart openclaw`**。容器启动脚本会在邀请后自动调用 Matrix **`/join` API**（等同 Element 里点「接受」）；若你仍看不到房间，可 **重启 openclaw 容器** 或手动在「加入房间」粘贴 `volumes/openclaw/.matrix-team-room-id` 中的房间 ID。入群后请在房内 **显式 @ 对应账号**（如 **`@manager`** / **`@manager:localhost`**）；团队房配置了 **`requireMention`**，不 @ 则 OpenClaw 不会接单。若 @ 了仍无回复：多半是 **`openclaw agents add` 清掉了 `openclaw.json` 里的 Matrix 绑定** 或 **`.agent-tokens` 未生成**——请 **`docker compose … restart openclaw`** 拉取最新 `openclaw/openclaw-startup.sh`（会在注册 agents 后自动重新合并 Matrix 配置并刷新 token），并确认 `volumes/openclaw/.agent-tokens` 存在且非空。若需对同一房间重新发邀请，可删 `volumes/openclaw/.team-room-invites-done` 后再跑 `matrix/matrix-bootstrap-team-room.sh`。

查看 OpenClaw 日志：

```bash
docker compose -f deploy/docker-compose.yml --env-file .env logs -f openclaw
```

在容器内执行 OpenClaw CLI（遵守仓库内 `CLAUDE.md` 约定）：

```bash
docker compose -f deploy/docker-compose.yml --env-file .env exec openclaw openclaw --help
```

## 架构要点

- **Matrix**：Tuwunel；人机、机机消息通道。
- **Gateway-first**：OpenClaw 通过 Gateway 调度；Matrix 侧重通知与群协作。
- **自备 Element**：不内置网页版 Matrix 客户端。

## 常见问题

- **群里 @manager 返回 `HTTP 401` / `invalid x-api-key`**：不是 Matrix 问题，是 **LLM API 密钥不对**。请把 `.env` 里的 **`ANTHROPIC_API_KEY`** 换成 [Anthropic Console](https://console.anthropic.com/)（或你所用 Anthropic 兼容网关）的**真实 Key**，勿再使用 `sk-ant-xxxxx` 等占位符；保存后执行  
  `docker compose -f deploy/docker-compose.yml --env-file .env restart openclaw`。
- **使用 MiniMax 国内（Anthropic 兼容）做测试**：在项目根 **`.env`** 中配置（见 [MiniMax 文档](https://platform.minimaxi.com/docs/api-reference/text-anthropic-api)）：
  - **`ANTHROPIC_BASE_URL=https://api.minimaxi.com/anthropic`**
  - **`ANTHROPIC_API_KEY=`** 你在 MiniMax 开放平台申请的 Key（不是 `sk-ant-` 占位符）
  - **`MODEL_NAME=`** 文档列出的兼容模型名（如 `MiniMax-M2.1`，以控制台为准）  
  `deploy/docker-compose.yml` 已通过 **`env_file: .env`** 把上述变量注入 **openclaw** 容器；`openclaw/openclaw-startup.sh` 会把它们写入 **`volumes/openclaw/openclaw.json`** 的 **`env`**。改完后 **`restart openclaw`**。
- **群里报错 `Unknown model: anthropic/minimax-m25`（或其它非 `claude-` 模型名）**：OpenClaw 内置目录只认 **`anthropic/claude-*`**。只要配置了 **`ANTHROPIC_BASE_URL`** 且 **`MODEL_NAME`** 不是 **`claude-` 开头**，启动脚本会自动改用 **`minimax/<模型名>`** 并在 `openclaw.json` 里写入 **`models.providers.minimax`**（Anthropic Messages 兼容端点）。若你曾手动改过 `openclaw.json`，**重启 openclaw 容器** 即可重新同步。走官方 Anthropic、无自定义 Base URL 时仍使用 **`anthropic/<MODEL_NAME>`**。

## 命令

| 命令 | 说明 |
|------|------|
| **`make fresh`** / `./platform/deploy.sh --fresh` | **推荐**：清空 `volumes` 后重新部署 |
| `./platform/deploy.sh` / `make deploy` | 保留数据，build + up + 健康检查 |
| `make e2e-matrix` | Matrix mention 配置校验 + human→manager、arch→dev E2E（需栈已运行） |
| `make up` / `make down` / `make restart` | 启动 / 停止 / 重启 |
| `make logs` / `make ps` | 日志 / 状态 |
| `uv sync` / `make uv-sync` | 同步 Python 依赖 |
| `make test` | 全部测试（`uv run pytest tests/`，需 `.env`；完整项需栈已启动） |
| `make test-smoke` | 仅 smoke 用例（`pytest -m smoke`） |
| `make test-e2e` / `make test-integration` | 与 `make test` 相同 |
| `make clean` | 停止并清理卷（慎用） |

## Agent 角色

| Agent | 职责 |
|-------|------|
| **Manager** | 任务协调、项目管理 |
| **Arch** | 架构设计 |
| **Dev** | 开发 |
| **QA** | 测试 |
| **SRE** | 运维 |
| **Research** | 调研 |

## 文档

- **[用户手册（运行原理 + 使用）](docs/user-manual.md)** — Synapse/OpenClaw 如何配合、Element 协作  
- **[开发手册与手测](docs/developer-handbook.md)** — 改配置/镜像、pytest、`make e2e-matrix`、Element 手测清单  
- [USER_MANUAL.md](USER_MANUAL.md) — 极简入口（指向上述手册）  
- [部署指南](docs/deployment-guide.md)
- [安全加固](docs/security.md)
- [最佳实践](docs/best-practices.md)
- [人机交互协议](docs/protocols/human-agent-protocol.md)

## 许可证

MIT
