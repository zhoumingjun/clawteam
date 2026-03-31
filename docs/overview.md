# Claw Team 项目概述

## 1. 项目背景与意义

### 1.1 背景

随着 AI 技术的快速发展，软件开发生命周期（SDLC）正在经历智能化变革。传统的软件开发模式依赖大量人力进行需求分析、设计、编码、测试和运维，成本高、效率有限。

### 1.2 意义

Claw Team 旨在构建一个 **开箱即用的 AI 软件研发工厂**，通过多个专业化的 AI Agent 组成虚拟团队，覆盖软件开发的全生命周期。用户只需下达指令，虚拟团队即可协作完成从需求到交付的全流程工作。

**核心价值**：
- 降低软件开发的门槛和成本
- 提升开发效率，实现 24/7 不间断工作
- 通过标准化流程保证质量一致性
- 模拟真实团队协作模式，支持人机协同

## 2. 项目目标

### 2.1 总体目标

**直接使用虚拟 AI 团队进行软件开发，覆盖完整 SDLC**

### 2.2 具体目标

| 阶段 | Agent | 职责 |
|------|-------|------|
| 需求分析 | research / manager | 需求调研、拆解、优先级排序 |
| 系统设计 | arch | 架构设计、技术选型、方案评审 |
| 代码开发 | dev | 编写代码、实现功能 |
| 测试验证 | qa | 自动化测试、回归测试、质量把关 |
| 部署发布 | sre | CI/CD、容器化、发布流程 |
| 运维监控 | sre | 监控、日志、问题排查 |
| 项目管理 | manager | 全流程协调、进度跟踪 |

### 2.3 用户交互

- 人类用户通过 Matrix（Tuwunel + 自备 Matrix 客户端）与 Agent 直接交互
- 全程保持"人心在环"（Human-in-the-loop），可随时干预
- 每个项目创建独立的 Team（Manager + 相关 Agent + Human）

## 3. 技术架构

### 3.1 核心组件

| 组件 | 技术选型 | 说明 |
|------|----------|------|
| AI Provider | Claude API | 各 Agent 独立 API Key |
| 开发工具 | Claude Code CLI | 每个 Agent 容器内运行 |
| 消息中间件 | Tuwunel (Matrix) | Agent 间 + 人机通信 |
| Matrix 客户端 | 自备（如 Element） | 人类用户连接 Homeserver |
| 容器编排 | Docker Compose | 一键启动 |
| 运行时管理 | mise | 统一管理 Node/Python/Go 等工具链 |
| Shell | zsh + oh-my-zsh + starship | 现代化终端体验 |

### 3.2 Agent 角色定义

| Agent | 核心定位 | 内置 Skill |
|-------|----------|------------|
| manager | 任务分发、团队协调 | 项目管理、任务拆解、进度跟踪 |
| arch | 架构设计、技术选型 | 系统设计、代码评审、技术调研 |
| dev | 代码开发 | Claude Code、git、代码生成 |
| qa | 测试、质量保证 | 自动化测试、回归测试 |
| sre | 部署、运维 | CI/CD、容器化、监控 |
| research | 技术调研 | 文档检索、代码分析 |

### 3.3 Agent 配置模型

每个 Agent 使用 OpenClaw 的 Markdown 驱动配置：

- `SOUL.md` - Agent 身份、安全规则、通信模型
- `AGENTS.md` - 技能和任务工作流
- `HEARTBEAT.md` - 心跳检查例程

### 3.4 网络架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose Network                    │
│                                                              │
│  ┌──────────────┐         ┌──────────────────────────────┐   │
│  │  Tuwunel     │◄────────│ OpenClaw（Gateway + 多 Agent）│   │
│  │  (Matrix HS) │  :8008  │  逻辑角色：manager/arch/…    │   │
│  └──────────────┘         └──────────────────────────────┘   │
│         ▲                                                    │
│  （Human 经 127.0.0.1:8008 等连接 Tuwunel，房内 @ 各角色）     │
│         │                                                    │
│  ┌──────────────────────────────────────────────────────────┐│
│  │                   Docker Volumes                          ││
│  │  tuwunel-data/  openclaw/（bind mount，见 deploy/compose） ││
│  └──────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## 4. 约束与限制

### 4.1 网络端口

| 服务 | 主机端口（默认，见 `.env`） |
|------|----------|
| Tuwunel（Matrix HS） | `127.0.0.1:8008` |

### 4.2 存储方案

- Tuwunel 与 OpenClaw 状态通过 **`volumes/tuwunel-data`**、**`volumes/openclaw`**（bind mount）持久化
- 便于备份与迁移（见 **`platform/volumes/`**）

### 4.3 工具链

- **运行时**：Docker / Docker Compose（见 `Makefile`、`platform/deploy.sh`）。
- **Python 测试**：[uv](https://docs.astral.sh/uv/) + pytest（`pyproject.toml`）。

### 4.4 安全约束

- Agent 间通信通过 Matrix 协议加密
- API Key 通过环境变量注入，不写入配置文件
- 容器间网络隔离

## 5. 需求规格

### 5.1 功能需求

| ID | 需求 | 优先级 |
|----|------|--------|
| F01 | 支持 6 种 Agent 角色（manager/arch/dev/qa/sre/research） | P0 |
| F02 | Agent 间通过 Matrix 协议通信 | P0 |
| F03 | 人类用户通过 Matrix 客户端与 Agent 交互 | P0 |
| F04 | 每个 Agent 使用 Claude Code CLI 进行代码开发 | P0 |
| F05 | 每个 Agent 有独立的 SOUL.md/AGENTS.md/HEARTBEAT.md 配置 | P0 |
| F06 | 通过 docker-compose 一键启动所有服务 | P0 |
| F07 | 支持按项目创建独立 Team | P1 |
| F08 | 人类可随时干预 Agent 决策 | P1 |
| F09 | Agent 配置通过 Volume 持久化 | P1 |
| F10 | 支持横向扩展添加新 Agent 类型 | P2 |

### 5.2 非功能需求

| ID | 需求 | 目标 |
|----|------|------|
| NF01 | 开箱即用 | 拉取镜像后，一条命令启动完整环境 |
| NF02 | 跨平台 | 支持 Linux/macOS/Windows (via Docker) |
| NF03 | 资源占用 | 最小化镜像体积，节省资源 |
| NF04 | 可维护性 | Markdown 驱动的配置，便于维护和扩展 |
| NF05 | 可观测性 | Agent 状态、任务进度可追踪 |

## 6. 交付形式

### 6.1 Docker Compose

以仓库内 **`deploy/docker-compose.yml`** 为准，当前 MVP 仅包含 **`tuwunel`** 与 **`openclaw`** 两个服务；多 Agent 由 OpenClaw Gateway 在同一容器内调度，而非每角色独立容器。

### 6.2 目录结构

```
clawteam/
├── deploy/
│   ├── docker-compose.yml
│   ├── Dockerfile.synapse   # 遗留（Synapse）
│   ├── Dockerfile.openclaw
│   └── homeserver.yaml    # 遗留
├── config/openclaw/    # 各 workspace-* Markdown 模板
├── matrix/                 # Matrix 团队协作脚本（密码、团队房、mention E2E）
├── openclaw/               # OpenClaw 容器入口等
│   └── openclaw-startup.sh
├── platform/               # 部署与基础设施
│   ├── deploy.sh
│   ├── matrix-ensure-user.py
│   ├── sync-synapse-config.sh
│   └── volumes/            # 备份/恢复
├── Makefile
├── docs/
└── volumes/
    ├── tuwunel-data/
    └── openclaw/
```

## 7. 参考架构

本项目参考 [HiClaw](https://github.com/alibaba/hiclaw) 的架构设计理念，并在此基础上进行定制：

- **Matrix**：当前 MVP 使用 **Tuwunel**（见 `deploy/docker-compose.yml`）
- 多个专业化 Agent 由 **OpenClaw Gateway** 统一调度
- Matrix 客户端自备（如 Element）

## 8. 版本信息

- OpenClaw：镜像内 pin 版本见 `deploy/Dockerfile.openclaw`
- Tuwunel：`ghcr.io/matrix-construct/tuwunel` OCI 镜像
- Matrix 客户端：自备（如 Element）
