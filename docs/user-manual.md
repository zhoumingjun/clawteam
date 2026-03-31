# Claw Team 用户手册

面向**部署本仓库、用 Matrix 客户端与多 Agent 协作**的用户。更细的加固与生产部署见 [deployment-guide.md](deployment-guide.md)。

---

## 1. 运行原理（你要理解的三件事）

### 1.1 两个容器，一条消息链

| 组件 | 作用 |
|------|------|
| **Tuwunel**（[matrix-construct/tuwunel](https://github.com/matrix-construct/tuwunel)） | Matrix Homeserver：账号、房间、消息、提及（mention）的权威来源。 |
| **OpenClaw**（[openclaw/openclaw](https://github.com/openclaw/openclaw)） | Gateway + 多 Agent：每个角色有独立 Matrix 登录，订阅同一**团队房间**；收到「指向自己的 @」后走 LLM 回复，再发回房间。 |

人类不直接连 OpenClaw HTTP，而是通过 **Matrix 客户端（如 Element）** 连 Tuwunel，在**同一个群里**发消息。

### 1.2 启动后系统为你做了什么

1. **Tuwunel** 先就绪；`devops/deploy.sh` 用 Client API 按 `.env` 注册/登录人类与各 Agent 用户。
2. **OpenClaw** 启动后：注册/刷新 Matrix 设备、写 **`volumes/openclaw/openclaw.json`**、把各 Agent 的 Matrix channel **绑定到同一团队房间**（房间名默认与配置相关，如「Claw Team」）。
3. 脚本会尽量**自动接受邀请**（等价于你在 Element 里点「加入房间」）。若仍看不到房间，可用 `volumes/openclaw/.matrix-team-room-id` 手动加入。

### 1.3 为什么在群里必须 @

团队房通常开启 **`requireMention`**：只有消息里**明确 @ 某个 Agent**（或符合配置的 mention 规则）时，OpenClaw 才会把该消息交给对应角色处理。这样避免刷屏每条都触发模型。

**互动方式**：`@manager:localhost` 或客户端里显示的短名 `@manager`（取决于客户端与注入格式）；Agent 之间同理，需在正文或 pill 里指向对方 MXID。

---

## 2. 你将得到什么

- 本机（默认）**`http://127.0.0.1:8008`** 上的 Tuwunel，供 Element 连接。
- Docker 内的 **OpenClaw**，状态在 **`volumes/openclaw/`**（含 `openclaw.json`、token、会话等）。
- **自备 Element 桌面版**（推荐）：仓库不内置网页版客户端。

---

## 3. 环境要求

| 项目 | 说明 |
|------|------|
| 系统 | macOS / Linux / Windows（Docker Desktop 或兼容） |
| Docker | `docker`、`docker compose` 可用 |
| 网络 | 首次 build 需拉镜像与 npm 依赖 |

---

## 4. 配置 `.env`

```bash
cp .env.example .env
```

至少配置：

| 变量 | 说明 |
|------|------|
| `ANTHROPIC_API_KEY` | LLM 密钥（占位符无法对话） |
| `MODEL_NAME` | 与所用 API 一致的模型名 |
| `ANTHROPIC_BASE_URL` | 仅在使用 Anthropic **兼容网关**（如 MiniMax）时填写 |
| `HUMAN_PASSWORD` | 人类账号 `@human:<服务器名>` 的登录密码 |
| `MANAGER_PASSWORD` 等 | 各 Agent 的 Matrix 密码；建议全部显式设置 |

Homeserver 本地默认：`MATRIX_SERVER_NAME=localhost`、`MATRIX_PORT=8008`（变量名沿用历史）。细节以 `.env.example` 注释为准。

---

## 5. 部署与确认

在项目根目录：

```bash
make fresh      # 推荐验收：清空 volumes 后完整拉起
# 或
make deploy     # 保留数据，重新 build/up
```

确认 Tuwunel：

```bash
curl -sS "http://127.0.0.1:${MATRIX_PORT:-8008}/_matrix/client/versions"
```

确认容器：

```bash
docker compose -f containers/docker-compose.yml --env-file .env ps
```

改 **LLM 或 Matrix 密码** 后通常需要：

```bash
docker compose -f containers/docker-compose.yml --env-file .env restart openclaw
```

---

## 6. 日常使用：Element 里怎么协作

1. 安装 [Element](https://element.io/) **桌面版**（浏览器连 `http://` Homeserver 易受混合内容限制）。
2. Homeserver 填 **`http://127.0.0.1:8008`**（或你的端口）。
3. 登录 **`@human:localhost`**（若改过 `MATRIX_SERVER_NAME`，域名与之一致），密码为 **`HUMAN_PASSWORD`**。
4. 进入团队房间后，需要谁响应就 **@ 谁**（如 `@manager` / `@dev`）。plain 闲聊未 @ 时，Agent 通常不会回复。

### 6.1 登录或房间异常时

按顺序尝试：

1. `make fresh`（清空 volumes 并重建全部服务与账号）
2. `docker compose -f containers/docker-compose.yml --env-file .env restart openclaw`

---

## 7. OpenClaw 命令行（必须在容器内）

主机直接跑 `openclaw` 可能缺 Matrix 依赖；请：

```bash
docker compose -f containers/docker-compose.yml --env-file .env exec openclaw openclaw --help
docker compose -f containers/docker-compose.yml --env-file .env exec openclaw openclaw health
```

查看日志：

```bash
docker compose -f containers/docker-compose.yml --env-file .env logs -f openclaw
```

---

## 8. LLM 报错 ≠ Matrix 坏了

群里若出现 **`HTTP 401` / `invalid x-api-key`**，优先检查 `.env` 的 **`ANTHROPIC_API_KEY`**、**`ANTHROPIC_BASE_URL`**、**`MODEL_NAME`**，再 `restart openclaw`。说明见根目录 [README.md](../README.md)「常见问题」。

---

## 9. 目录速查

| 路径 | 说明 |
|------|------|
| `containers/docker-compose.yml` | Compose 编排 |
| `volumes/tuwunel-data/` | Tuwunel 数据（勿提交） |
| `volumes/openclaw/` | OpenClaw 与 `openclaw.json` |
| `config/agents/` | Workspace 模板（只读挂载进容器） |

---

## 10. 延伸阅读

- [README.md](../README.md) — 命令总表、模型名与 MiniMax 说明  
- [developer-handbook.md](developer-handbook.md) — 开发与手测  
- [deployment-guide.md](deployment-guide.md) — 部署细节  
- [security.md](security.md)、[best-practices.md](best-practices.md)  
