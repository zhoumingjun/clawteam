# Claw Team 执行计划

## 概述

本文档定义 Claw Team 项目的完整开发计划，覆盖从初始化到 E2E 验证的全流程。

---

## 第一阶段：基础设施

| ID | Spec | 名称 | 目标 | 主要交付物 | 依赖 |
|----|------|------|------|------------|------|
| SPEC-001 | init-project | 项目初始化 | 建立项目基础结构 | 目录结构、Makefile、.env.example | - |
| SPEC-002 | docker-compose | 服务编排 | 定义 docker-compose 编排 | docker-compose.yml、网络配置 | SPEC-001 |
| SPEC-003 | conduit-matrix | Matrix 服务器 | 集成 Conduit | Conduit 配置、用户/房间初始化脚本 | SPEC-001 |
| SPEC-004 | storage-volumes | 存储卷设计 | 配置数据持久化 | Volume 配置、备份恢复脚本 | SPEC-001 |

---

## 第二阶段：Agent 配置

| ID | Spec | 名称 | 目标 | 主要交付物 | 依赖 |
|----|------|------|------|------------|------|
| SPEC-005 | agent-config-manager | Manager Agent | 配置 Manager | SOUL.md、AGENTS.md、HEARTBEAT.md | SPEC-002 |
| SPEC-006 | agent-config-arch | Arch Agent | 配置 Arch | SOUL.md、AGENTS.md、HEARTBEAT.md | SPEC-002 |
| SPEC-007 | agent-config-dev | Dev Agent | 配置 Dev | SOUL.md、AGENTS.md、HEARTBEAT.md | SPEC-002 |
| SPEC-008 | agent-config-qa | QA Agent | 配置 QA | SOUL.md、AGENTS.md、HEARTBEAT.md | SPEC-002 |
| SPEC-009 | agent-config-sre | SRE Agent | 配置 SRE | SOUL.md、AGENTS.md、HEARTBEAT.md | SPEC-002 |
| SPEC-010 | agent-config-research | Research Agent | 配置 Research | SOUL.md、AGENTS.md、HEARTBEAT.md | SPEC-002 |

---

## 第三阶段：协议与部署

| ID | Spec | 名称 | 目标 | 主要交付物 | 依赖 |
|----|------|------|------|------------|------|
| SPEC-011 | human-agent-protocol | 人机交互协议 | 定义协作流程 | Team 创建流程、通信规范文档 | SPEC-003, SPEC-005~010 |
| SPEC-012 | deployment-guide | 部署指南 | 提供安装部署 | 安装脚本、使用文档、故障排查 | SPEC-002~011 |
| SPEC-013 | smoke-tests | 烟雾测试 | 验证基础功能 | 健康检查脚本、单元测试 | SPEC-002~012 |

---

## 第四阶段：E2E 验证

| ID | Spec | 名称 | 目标 | 主要交付物 | 依赖 |
|----|------|------|------|------------|------|
| SPEC-014 | e2e-tests | E2E 测试方案 | 验证团队协作 | E2E 测试框架、测试用例 | SPEC-013 |
| SPEC-015 | demo-project | 演示项目 | 执行真实项目开发 | 交付代码、测试报告 | SPEC-014 |

---

## 测试方案

### 测试分层

```
┌─────────────────────────────────────────────────────────────┐
│                    E2E 测试 (SPEC-014)                       │
│         虚拟团队开发真实项目，验证完整 SDLC 运转                │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    集成测试 (SPEC-013)                        │
│              服务健康检查、组件通信、配置持久化                  │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    单元测试 (各 Spec 内)                       │
│                  各组件配置正确性验证                          │
└─────────────────────────────────────────────────────────────┘
```

---

### SPEC-013: 烟雾测试

| # | 测试项 | 验证方式 | 成功标准 |
|----|--------|----------|----------|
| 1 | Docker 构建 | `make build` | 无错误 |
| 2 | 服务启动 | `make up` | 所有服务 Up |
| 3 | Conduit 健康 | HTTP 请求 `/_matrix/client/versions` | 返回 200 + 版本信息 |
| 4 | Element Web 健康 | HTTP 请求 `/` | 返回 HTML |
| 5 | Agent 进程运行 | `docker compose exec` | 进程存在 |
| 6 | Matrix 用户创建 | 脚本执行 | 用户创建成功 |
| 7 | 房间创建 | 脚本执行 | 房间创建成功 |
| 8 | 人机通信 | Element Web | Human 与 Agent 互发消息 |
| 9 | Agent 间通信 | Matrix 日志 | Agent 消息传递 |
| 10 | 配置持久化 | 重启服务 | 配置不丢失 |

---

### SPEC-014: E2E 测试

#### 测试目标
验证虚拟团队能够**自动协作开发完整项目**

#### 测试流程
```
1. Human 下达任务 (REST API 开发)
   ↓
2. Manager 接收、拆解任务、创建 Team
   ↓
3. Arch 输出架构设计文档
   ↓
4. Dev 实现代码
   ↓
5. QA 编写并执行测试
   ↓
6. SRE 构建镜像、部署服务
   ↓
7. 验证服务可用
   ↓
8. Manager 向 Human 汇报
```

#### 验证检查点

| 阶段 | 检查项 | 交付物 | 验证方式 |
|------|--------|--------|----------|
| 架构设计 | 架构文档 | `architecture.md` | 文件存在、内容完整 |
| 代码开发 | 源代码 | `src/` | 代码可编译 |
| 代码评审 | 评审记录 | `code-review.md` | 评审通过 |
| 单元测试 | 测试代码 | `tests/` | 测试通过 |
| 测试覆盖率 | 覆盖率报告 | `coverage/` | 覆盖率 > 60% |
| Dockerfile | 镜像构建 | `docker build` | 构建成功 |
| 部署 | 服务运行 | `curl localhost:PORT` | HTTP 200 |

#### 交付物清单
```
outputs/{project-name}/
├── architecture.md          # 架构设计
├── code/                    # 源代码
│   ├── src/
│   └── tests/
├── coverage/                # 测试覆盖率报告
├── deployment/              # 部署配置
│   ├── Dockerfile
│   └── docker-compose.yml
└── report.md               # 最终报告
```

---

### SPEC-015: 演示项目

| 项目 | 描述 | 复杂度 | 预期产出 |
|------|------|--------|----------|
| REST TODO API | Go/Node.js TODO CRUD API | ★★☆ | 可运行的服务 |

---

## 执行命令

```bash
# 构建所有镜像
make build

# 启动服务
make up

# 查看状态
docker compose ps

# 运行烟雾测试
make test-smoke

# 运行 E2E 测试
make test-e2e

# 查看日志
make logs

# 停止服务
make down
```

---

## 目录结构

```
clawteam/
├── docs/
│   ├── overview.md         # 项目概述
│   └── execution-plan.md   # 本文档
├── configs/
│   ├── agents/
│   │   ├── manager/
│   │   ├── arch/
│   │   ├── dev/
│   │   ├── qa/
│   │   ├── sre/
│   │   └── research/
│   └── matrix/
├── volumes/
├── tests/
│   ├── smoke/
│   └── e2e/
├── docker-compose.yml
└── Makefile
```

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v0.1 | 2026-03-30 | 初始版本 |
