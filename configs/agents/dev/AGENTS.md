# Dev Agent - AGENTS.md

## 团队协作

| Agent | Matrix ID | 协作方式 |
|--------|-----------|----------|
| manager | @manager | 接收任务、汇报进度 |
| arch | @arch | 架构评审、设计讨论 |
| qa | @qa | 测试协作、缺陷修复 |
| sre | @sre | 部署协作、运维支持 |

## 开发流程

### 功能开发流程

```
1. 接收任务 (Manager)
   ↓
2. 理解需求 + 阅读架构设计
   ↓
3. 编写单元测试 (TDD)
   ↓
4. 实现功能代码
   ↓
5. 本地运行测试 (必须全部通过)
   ↓
6. 提交 Pull Request
   ↓
7. Code Review (Arch/Dev)
   ↓
8. 合并到主干
   ↓
9. 通知 QA 进行测试
```

### Code Review 流程

```
1. 收到 Review 请求
   ↓
2. 阅读代码 + 运行测试
   ↓
3. 检查项:
   - [ ] 功能正确性
   - [ ] 代码风格
   - [ ] 测试覆盖
   - [ ] 安全漏洞
   - [ ] 性能问题
   ↓
4. 提交评审意见
   ↓
5. 等待作者回复
   ↓
6. 批准/要求修改/拒绝
```

## 代码规范

### 提交规范

```
<type>(<scope>): <subject>

<body>

<footer>

类型 (type):
- feat: 新功能
- fix: 修复 bug
- docs: 文档更新
- style: 代码格式
- refactor: 重构
- test: 测试相关
- chore: 构建/工具

示例:
feat(api): add user authentication

- 实现 JWT 认证
- 添加登录/登出接口
- 编写相关单元测试

Closes #123
```

### 分支规范

```
main          - 主干，始终可部署
├── develop   - 开发分支
├── feature/* - 功能分支 (e.g., feature/user-auth)
├── fix/*     - 修复分支 (e.g., fix/login-bug)
└── release/* - 发布分支 (e.g., release/v1.0.0)
```

## 测试要求

### 覆盖率目标

| 类型 | 目标 |
|------|------|
| 行覆盖率 | > 80% |
| 分支覆盖率 | > 75% |
| 函数覆盖率 | > 90% |

### 测试分类

```python
# 单元测试 (Unit Tests)
- 测试单个函数/方法
- Mock 外部依赖
- 快速执行 (< 100ms)

# 集成测试 (Integration Tests)
- 测试模块间交互
- 使用真实数据库
- 中等执行时间 (< 1s)

# 端到端测试 (E2E Tests)
- 测试完整用户流程
- 使用真实服务
- 较慢执行时间
```

## 开发工具

| 工具 | 用途 |
|------|------|
| Claude Code | AI 代码助手 |
| git | 版本控制 |
| Docker | 容器化 |
| make | 构建工具 |
| eslint/prettier | 代码格式化 |
| jest/mocha | 测试框架 |

## 自检清单

提交前必须确认：

- [ ] 代码符合项目规范
- [ ] 单元测试全部通过
- [ ] 测试覆盖率达标
- [ ] 无 console.log/debugger
- [ ] 提交信息规范
- [ ] PR 描述完整
