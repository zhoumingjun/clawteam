# Todo Demo - Claw Team 演示项目

## 项目背景

本项目是一个简单的 Todo 列表应用，用于演示 Claw Team 虚拟团队如何协作完成软件开发。

**目标**: 展示完整的 SDLC 流程，从需求到部署

## 团队分工

| Agent | 职责 | 具体任务 |
|-------|------|----------|
| **Manager** | 任务协调 | 接收需求、拆解任务、跟踪进度、汇报状态 |
| **Arch** | 架构设计 | 技术选型、设计系统架构、代码评审 |
| **Dev** | 代码开发 | 实现前端、后端、编写单元测试 |
| **QA** | 测试验证 | 设计测试用例、执行测试、验证质量 |
| **SRE** | 部署运维 | 编写 Dockerfile、配置 CI/CD、部署服务 |

## 工作流程

```
Human (你)
    │
    │ "用 Claw Team 开发一个 Todo 应用"
    ▼
Manager
    │
    ├── 分析需求
    ├── 拆解任务
    │   ├── TASK-1: 架构设计 (@arch)
    │   ├── TASK-2: 前端开发 (@dev)
    │   ├── TASK-3: 后端开发 (@dev)
    │   ├── TASK-4: 单元测试 (@qa)
    │   ├── TASK-5: 集成测试 (@qa)
    │   └── TASK-6: 部署配置 (@sre)
    │
    ├── 分配任务
    └── 跟踪进度
    │
    ▼
并行执行
    │
    ├─ Arch: 输出架构文档
    ├─ Dev: 实现代码
    ├─ QA: 编写测试
    └─ SRE: 准备部署
    │
    ▼
Manager 汇总 → Human 交付
```

## 项目结构

```
todo-demo/
├── README.md           # 本文档
├── SPEC.md             # 需求规格
├── src/
│   └── todo.html      # Todo 前端应用
├── tests/
│   └── todo.test.js   # 测试用例
├── deployment/
│   └── Dockerfile     # 容器化部署
├── Makefile           # 开发命令
└── docs/
    ├── architecture.md  # 架构文档
    └── test-report.md   # 测试报告
```

## 快速开始

### 前提条件

- Docker
- make

### 启动开发

```bash
# 进入项目目录
cd examples/todo-demo

# 启动本地开发服务器
make dev

# 运行测试
make test

# 构建生产版本
make build

# 部署
make deploy
```

## 技术栈

| 组件 | 技术 |
|------|------|
| 前端 | HTML5 + JavaScript |
| 后端 | Node.js + Express |
| 数据库 | SQLite |
| 容器化 | Docker |
| 测试 | Jest |
| CI/CD | GitHub Actions |

## 演示步骤

1. **启动服务**: `make dev`
2. **打开浏览器**: http://localhost:3000
3. **添加 Todo**: 输入内容并提交
4. **完成 Todo**: 点击复选框
5. **删除 Todo**: 点击删除按钮

## 角色交互示例

### Manager 任务分配

```
@manager: 收到任务：开发 Todo 应用

任务卡片:
- TASK-001: 架构设计 (@arch) - P0
- TASK-002: 前端开发 (@dev) - P1
- TASK-003: 后端开发 (@dev) - P1
- TASK-004: 单元测试 (@qa) - P1
- TASK-005: 集成测试 (@qa) - P2
- TASK-006: 部署配置 (@sre) - P2
```

### Arch 架构输出

```
@arch: 架构设计完成

产出:
- architecture.md (系统架构图)
- 技术选型报告
- API 设计文档
```

### Dev 代码实现

```
@dev: 前端开发完成

产出:
- src/todo.html (完整功能)
- README.md (使用说明)
```

### QA 测试验证

```
@qa: 测试完成

产出:
- tests/todo.test.js (12 个测试用例)
- 测试覆盖率: 85%
- 所有测试通过 ✅
```

### SRE 部署配置

```
@sre: 部署完成

产出:
- Dockerfile
- docker-compose.yml
- 服务运行在 http://localhost:3000
```

## 演示验证清单

- [ ] Manager 接收任务
- [ ] Arch 完成架构设计
- [ ] Dev 实现代码
- [ ] QA 验证测试
- [ ] SRE 完成部署
- [ ] 人类验收通过

---

*此演示项目用于展示 Claw Team 虚拟团队的协作能力*
