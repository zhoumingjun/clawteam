# Claw Team

**开箱即用的 AI 软件研发工厂**

多个专业化 Agent（Manager、Product、Arch、Dev、QA、SRE、Research）通过 **Matrix（[Tuwunel](https://github.com/matrix-construct/tuwunel)）** 协作，运行时由 **OpenClaw Gateway** 统一管理。Agent 名单由 `config/agents/team.yaml` 统一定义，增删角色只需编辑该文件并新建/删除对应目录。

## 快速开始

```bash
git clone https://github.com/zhoumingjun/clawteam.git
cd clawteam
cp .env.example .env
# 编辑 .env：填写 ANTHROPIC_API_KEY

make fresh
```

## 目录结构

| 路径 | 用途 |
|------|------|
| `containers/` | 容器定义：`docker-compose.yml`、Dockerfile、启动脚本、patches |
| `config/agents/` | 各 Agent 的 workspace 模板（IDENTITY、SOUL、TOOLS 等） |
| `devops/` | 部署与运维脚本（`deploy.sh`、`stack-check.sh`） |
| `volumes/` | 运行时数据（Tuwunel DB、OpenClaw 状态，`.gitignore`） |
| `tests/` | pytest 回归 + Shell E2E 测试 |
| `docs/` | 设计与运维文档 |

## 使用 Element 与 Agent 对话

1. 打开 Element，Homeserver 填 **`http://127.0.0.1:8008`**（若改了 `MATRIX_PORT`，以 `.env` 为准）。
2. 使用 **`@human:localhost`**（若改了 `MATRIX_SERVER_NAME`，域名与之一致）登录，密码见 `.env` 的 `HUMAN_PASSWORD`。
3. 首次启动时 OpenClaw 自动建 **Claw Team** 房并邀请全员。在房内 **@manager** 即可交互；配置了 `requireMention`，不 @ 不触发。
4. 密码错误或看不到房间？执行 `make fresh` 重新部署即可。

查看日志：

```bash
docker compose -f containers/docker-compose.yml --env-file .env logs -f openclaw
```

## 架构要点

- **Matrix**：Tuwunel（Rust）作为 homeserver，人机/机机消息通道
- **Gateway-first**：OpenClaw 通过 Gateway 调度，Matrix 侧重通知与群协作
- **自备 Element**：不内置网页版 Matrix 客户端

## 命令

| 命令 | 说明 |
|------|------|
| `make fresh` | **推荐**：清空 volumes 后重新部署 |
| `make deploy` | 保留数据，build + up + 健康检查 |
| `make up` / `make down` / `make restart` | 启动 / 停止 / 重启 |
| `make logs` / `make ps` | 日志 / 状态 |
| `make test` | 全部测试（pytest） |
| `make test-smoke` | 仅 smoke 用例 |
| `make e2e-matrix` | Matrix mention E2E 测试 |
| `make stack-check` | 健康检查 |
| `make clean` | 停止并清理卷（慎用） |

## Agent 角色

> 完整名单见 [`config/agents/team.yaml`](config/agents/team.yaml)

| Agent | 职责 |
|-------|------|
| **Manager** | 任务协调、项目管理 |
| **Product** | 需求分析、Spec 编写、验收标准 |
| **Arch** | 架构设计 |
| **Dev** | 开发 |
| **QA** | 测试 |
| **SRE** | 运维 |
| **Research** | 调研 |

## 常见问题

- **@manager 返回 401 / invalid x-api-key**：LLM API 密钥不对。在 `.env` 填写真实 `ANTHROPIC_API_KEY` 后 `make restart`。
- **使用 MiniMax 国内测试**：设置 `ANTHROPIC_BASE_URL=https://api.minimaxi.com/anthropic`、`MODEL_NAME=MiniMax-M2.1` 及对应 Key，`make restart`。
- **Unknown model**：启动脚本根据 `ANTHROPIC_BASE_URL` + `MODEL_NAME` 自动选择 provider，`make restart` 即可同步。

## 文档

- [用户手册](docs/user-manual.md) — 运行原理与使用
- [开发手册](docs/developer-handbook.md) — 配置修改、测试
- [部署指南](docs/deployment-guide.md)
- [安全加固](docs/security.md)
- [最佳实践](docs/best-practices.md)
- [人机交互协议](docs/protocols/human-agent-protocol.md)

## 许可证

MIT
