# Claw Team

**开箱即用的 AI 软件研发工厂**

通过多个专业化 AI Agent 组成的虚拟团队，覆盖软件开发的全生命周期。

## 特性

- 🤖 **多 Agent 协作**: Manager、Arch、Dev、QA、SRE、Research 各司其职
- 💬 **Matrix 通信**: 基于 Matrix 协议的人机/机机交互
- 🔒 **安全优先**: 端口绑定本地、安全加固开箱即用
- 🐳 **一键部署**: Docker Compose 快速启动
- 🚀 **Gateway-first**: OpenClaw Agent 通过 Gateway RPC 接收指令

## 架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Claw Team                                │
│                                                              │
│  ┌─────────────┐      ┌─────────────┐                      │
│  │  Synapse   │◄────►│   Human    │                      │
│  │  (Matrix)  │      │   (你)      │                      │
│  └─────────────┘      └─────────────┘                      │
│         │                       │                            │
│  ┌──────────────────────────────────────────┐              │
│  │              Agent Team                    │              │
│  │  Manager │ Arch │ Dev │ QA │ SRE │ Res │              │
│  └──────────────────────────────────────────┘              │
│         │                       │                            │
│  ┌─────────────┐      ┌─────────────┐                      │
│  │  Gateway    │◄────►│ Element Web │                      │
│  │  (RPC)      │      │  (UI)        │                      │
│  └─────────────┘      └─────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

**架构说明**: OpenClaw Agent 是 **Gateway-first** 架构：
- Matrix channel 用于**发送通知**
- 指令通过 **Gateway RPC** 接收（`openclaw agent` 命令显式调用）
- Session 管理是显式的，不自动响应 @mention

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/zhoumingjun/clawteam.git
cd clawteam
```

### 2. 配置环境

```bash
cp .env.example .env
# 编辑 .env 填写 API Key 和密码
```

### 3. 启动服务

```bash
make up
```

### 4. 初始化用户

```bash
# 设置密码环境变量
export MANAGER_PASSWORD=xxx
export HUMAN_PASSWORD=xxx
export ARCH_PASSWORD=xxx
export DEV_PASSWORD=xxx
export QA_PASSWORD=xxx
export SRE_PASSWORD=xxx
export RESEARCH_PASSWORD=xxx

# 初始化 Matrix 用户
make init-user
```

### 5. 开始使用

- **Element Web**: http://localhost:10001
- 使用 `@human` 账号登录，开始与 Agent 团队协作

## 命令

| 命令 | 说明 |
|------|------|
| `make up` | 启动所有服务 |
| `make down` | 停止所有服务 |
| `make restart` | 重启所有服务 |
| `make logs` | 查看日志 |
| `make ps` | 查看服务状态 |
| `make init-user` | 初始化 Matrix 用户 |
| `make init-check` | 检查初始化状态 |
| `make test-smoke` | 运行烟雾测试 |
| `make test-e2e` | 运行 E2E 测试 |
| `make clean` | 清理 |

## Agent 团队

| Agent | 职责 |
|-------|------|
| **Manager** | 任务协调、项目管理 |
| **Arch** | 架构设计、技术选型 |
| **Dev** | 代码开发 |
| **QA** | 测试验证 |
| **SRE** | 部署运维 |
| **Research** | 技术调研 |

## 技术栈

- **Matrix 服务器**: Synapse
- **Web UI**: Element Web
- **Agent 框架**: OpenClaw (Gateway-first)
- **容器化**: Docker Compose
- **Agent 配置**: Markdown 文件驱动

## 项目结构

```
clawteam/
├── docker-compose.yml     # 服务编排
├── Makefile              # 命令入口
├── .env.example          # 环境变量模板
├── configs/
│   ├── synapse/         # Synapse 配置
│   ├── element/        # Element Web 配置
│   └── agents/          # Agent 配置
├── docs/                # 文档
├── examples/            # 示例项目
├── tests/               # 测试
└── scripts/             # 脚本
```

## 文档

- [部署指南](docs/deployment-guide.md)
- [安全加固](docs/security.md)
- [最佳实践](docs/best-practices.md)
- [人机交互协议](docs/protocols/human-agent-protocol.md)

## 许可证

MIT

---

**状态**: ✅ SPEC-001 ~ SPEC-023 全部完成 (2026-03-30)
