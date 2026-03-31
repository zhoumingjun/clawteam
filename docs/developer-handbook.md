# Claw Team 开发手册与手测指南

面向**在本仓库上改编排、改 OpenClaw 配置、改 Agent 提示词或做联调**的开发者。

---

## 1. 运行原理（开发视角）

### 1.1 数据流

```
Element ──► Tuwunel (C-S API) ◄──► OpenClaw (多 Matrix 账号 + Gateway)
                    │
              团队房间（group）
                    │
         human + manager + arch + dev + qa + sre + research
```

- **Tuwunel** 只负责 Matrix 协议与持久化（`volumes/tuwunel-data`）。
- **OpenClaw** 在单容器内跑 Gateway；每个 Agent 对应一套 Matrix 凭证，通过 **`openclaw.json`** 里的 `channels.matrix` / `bindings` / `agents` 与**同一房间**绑定。
- 入站是否算「被 @」由 OpenClaw Matrix 插件解析（本镜像可能对 `formatted_body` / `m.mentions` 有构建期补丁，见 `deploy/patch-*.mjs`）。

### 1.2 启动脚本职责

`containers/openclaw/entrypoint.sh`（由 Compose 挂载进容器）大致顺序：

1. 等 Matrix homeserver（Tuwunel）HTTP 就绪  
2. 确保各账号密码文件 / Human 密码  
3. 登录或注册 Matrix 用户、刷新 **`volumes/openclaw/.agent-tokens`**  
4. 拉起 Gateway  
5. 合并/写入 **`openclaw.json`**（Matrix 路由、群组策略、LLM env）  
6. `openclaw agents add …` 后**再次合并**，避免 CLI 清掉 Matrix 绑定（若失败见容器日志 WARNING）

### 1.3 配置「双份」

| 位置 | 性质 |
|------|------|
| `config/agents/**` | 版本化的 workspace **模板**，只读挂进容器 |
| `volumes/openclaw/**` | **运行态**（`openclaw.json`、sessions、拷入的 workspace） |

改模板后常需重启或让启动逻辑重新部署 workspace；改运行态后注意不要被下次启动覆盖。

---

## 2. 仓库按业务域划分

| 目录 | 内容 |
|------|------|
| `containers/` | `docker-compose.yml`（Tuwunel + OpenClaw）、`Dockerfile.openclaw`、`Dockerfile.synapse`（遗留）、`patch-*.mjs`、mention 注入 JS |
| `devops/` | `deploy.sh`、`matrix-ensure-user.py`、`sync-synapse-config.sh`（已无操作）、卷备份恢复 |
| `containers/openclaw/` | 容器入口 `entrypoint.sh` |
| `matrix/` | mention 相关 E2E |
| `config/agents/` | 各 `workspace-*/` Markdown |
| `tests/` | pytest（栈健康、Matrix API 等） |

---

## 3. 日常开发流程

### 3.1 只改 Agent 行为 / 提示词

1. 编辑 `config/agents/workspace-*/AGENTS.md`（或 `SOUL.md` 等）。
2. 重启 OpenClaw，或依赖启动脚本是否从模板覆盖 volume（以 `entrypoint.sh` 当前逻辑为准）。  
3. 在 Element 里 **@ 对应角色** 手测。

### 3.2 改 Tuwunel

1. 编辑 **`containers/docker-compose.yml`** 中 `tuwunel.environment`，或挂载自写 `tuwunel.toml`（见 [Tuwunel 配置](https://tuwunel.chat/configuration.html)）。
2. `docker compose -f containers/docker-compose.yml --env-file .env up -d tuwunel`。  
3. 勿与旧 `homeserver.yaml` 混用；遗留 Synapse 文件仅作参考。

### 3.3 改 OpenClaw 镜像（npm 版本、补丁）

1. 编辑 `containers/Dockerfile.openclaw`（如 `openclaw@` 版本）。
2. 编辑 `containers/patch-*.mjs` / `openclaw-matrix-mentions-inject.js`（锚点随上游 bundle 变化可能失效）。
3. `docker compose -f containers/docker-compose.yml --env-file .env build openclaw --no-cache` 后 `up -d` 或走 `make deploy`。

### 3.4 改 Compose 环境变量

改 `.env` 后通常 **`restart openclaw`**；改端口或卷挂载需评估 `devops/deploy.sh` 与文档中的路径。

### 3.5 团队房间名（按项目）

- **`PROJECT_NAME`**：若设置，启动脚本用它作为 **团队房显示名**（优先于 `TEAM_ROOM_NAME`）。  
- 房间仍由 manager 创建，human 与各 agent 被邀请并自动 join；房间 ID 缓存在 `volumes/openclaw/.matrix-team-room-id`。

---

## 4. 自动化测试

```bash
uv sync
make test           # pytest 全部
make test-smoke     # 仅 @pytest.mark.smoke
```

前提：`.env` 存在；**test_stack** 等用例要求 **tuwunel / openclaw 容器已运行**。

### 4.1 Matrix mention 集成 E2E

栈运行中、`.env` 中 **LLM Key 可用**：

```bash
make stack-check   # 容器 + Tuwunel HTTP + 团队房 ID + .agent-tokens
make e2e-matrix
```

- **`make e2e-matrix`**：`matrix/e2e-matrix-agents-core.sh`（`stack-check` → `verify-matrix-pairwise-config.sh` → `e2e-matrix-mentions.sh`），推荐 CI。
- **`make e2e-matrix-all`**：core + 间隔 **60s** + `e2e-matrix-manager-ping-dev.sh`（**sre→@dev**，文件名沿用历史；Synapse 发送体须含 `m.mentions` + `formatted_body` 的 matrix.to）。曾用 manager 发起时 dev 常不愿在正文写 `@manager`。镜像构建期另有 **`patch-openclaw-matrix-trust-m-mentions.mjs`**。校验回复含 `@sre`（正文或 HTML）+ `m.mentions` + `matrix.to`，且发送者不得为 sre（避免自发自收）。最长约 **300s**，90s 可重发一次 ping。

---

## 5. 手测清单（建议）

在 **Element** 连接本机 Tuwunel，进入团队房：

| 步骤 | 操作 | 期望 |
|------|------|------|
| 1 | `@manager` 发一句简短需求 | Manager 有回复 |
| 2 | 同一条或后续消息里出现 `@dev` / `@qa`（按你们提示词约定） | 出站消息含合理 mention（Element 显示为 pill） |
| 3 | 用某 Agent 账号（若有 token 脚本）在房内 `@` 另一 Agent | 被 @ 方在 `requireMention` 下应接单 |
| 4 | 改 `.env` 中 `ANTHROPIC_API_KEY` 为错误值再发消息 | 应出现 LLM 401 类错误，而非静默无日志 |

CLI 抽查：

```bash
curl -sf "http://127.0.0.1:${MATRIX_PORT:-8008}/_matrix/client/versions"
docker compose -f containers/docker-compose.yml --env-file .env exec openclaw openclaw health
```

---

## 6. 约束与约定

- **OpenClaw CLI**：在容器内执行（见根目录 `CLAUDE.md`）。  
- **上游问题**：Matrix mention、Element `formatted_body` 等与 OpenClaw 行为相关时，可对照 [openclaw/openclaw](https://github.com/openclaw/openclaw) issue；本仓库通过 **构建期 patch** 做过部分对齐。  
- **Agent 群发互 @ 无响应**：对照官方 [Matrix channel — Bot to bot rooms](https://docs.openclaw.ai/channels/matrix#bot-to-bot-rooms)：`channels.matrix.allowBots` 须为 `"mentions"` 或 `true`；本仓库启动脚本已合并 `allowBots: "mentions"`（与 `requireMention` 同用更安全）。  
- **Tuwunel**：[github.com/matrix-construct/tuwunel](https://github.com/matrix-construct/tuwunel)，文档 [tuwunel.chat](https://tuwunel.chat/)。

---

## 7. 延伸阅读

- [user-manual.md](user-manual.md) — 最终用户如何使用  
- [deployment-guide.md](deployment-guide.md) — 部署与排错深化  
- [overview.md](overview.md) — 架构与目录总览  
- [protocols/human-agent-protocol.md](protocols/human-agent-protocol.md) — 人机协作约定  
