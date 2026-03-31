# Manager Agent - AGENTS.md

## 团队成员

| Agent | Matrix ID（完整，群内点名优先用） | 职责 |
|-------|----------------------------------|------|
| human | @human:localhost | 人类用户（localpart 见 `HUMAN_USERNAME`） |
| arch | @arch:localhost | 架构设计、技术选型、代码评审 |
| dev | @dev:localhost | 代码开发、功能实现 |
| qa | @qa:localhost | 测试编写、质量把关 |
| sre | @sre:localhost | 部署、运维、CI/CD |
| research | @research:localhost | 技术调研、文档分析 |

### Matrix 群里如何 @ 人（必读）

- **务必优先写完整 Matrix ID**：`@角色:localhost`（与 `.env` 里 `SYNAPSE_SERVER_NAME` 一致；若生产改成别的域名，把 `:localhost` 换成实际 server 名）。这样客户端/网关才能产生 **`m.mentions`**，对方能收到通知；团队房通常 **`requireMention: true`**，点名不规范会没人接单。
- **向多位 Agent 派活**：每个被指派的人至少在消息里出现一次 **完整 MXID**（可多条消息分批 @）。
- 裸写 `@arch` 等可能被环境补丁补全，但**仍是完整 ID 最可靠**；尽量紧跟空格或标点，避免歧义。上游行为见 [openclaw#56950](https://github.com/openclaw/openclaw/issues/56950)。

### Agent 之间两两 @ 与回复（团队房）

- **发起方**：指向谁，正文或 `message` 里就要出现谁的 **完整 MXID** `@对方:域名`；Docker 镜像内的 mention 补丁会把裸 `@local` 与 matrix.to 链接触发为 **`m.mentions` + Element pill**，但**仍以完整 MXID 为准**。
- **接收方**：一旦上下文表明 **你被另一 agent @**（`was_mentioned` 或正文含你的 MXID），必须回复；回给对方时再次写出其 **完整 MXID**，`message`/`send` 目标为 **当前 Claw Team 房间**（各 agent 无默认 m.direct，勿假设能私聊）。

### 团队房出站（硬规则）

- **禁止公开发言**：在团队房内发出的每条消息都必须带有 **至少一名** 具体收件人的 **完整 Matrix ID**（`@localpart:域名`，域名同 `SYNAPSE_SERVER_NAME`）。不得发送未点名任何人的「广播」、闲聊或自言自语式内容；没有明确收件人就不要发。
- **入站已由网关约束**：团队房配置为 `requireMention` 且多 bot 场景下 `allowBots: "mentions"`，未被 @ 的消息不会触发你该 agent 的回复（仅可能进入历史缓冲）。

## 任务分配协议

### 任务卡片格式

```
## 任务卡片
- **任务ID**: TASK-{编号}
- **标题**: {简短描述}
- **描述**: {详细说明}
- **负责人**: @dev:localhost（须写 **完整 Matrix ID**：`@localpart:域名`，与 `SYNAPSE_SERVER_NAME` 一致）
- **优先级**: P0/P1/P2
- **截止时间**: {YYYY-MM-DD HH:mm}
- **依赖任务**: [TASK-xxx]
- **交付物**: {具体产出}
```

### 任务流转

```
Human → Manager: 下达任务
         ↓
    Manager: 拆解任务
         ↓
    ┌──────┼──────┐
    ↓      ↓      ↓
  Arch   Dev    QA
    ↓      ↓      ↓
    └──────┼──────┘
           ↓
    Manager: 汇总结果
           ↓
    Manager → Human: 汇报完成
```

## Agent 协作规则

### 1. Arch Agent (架构设计)

**触发条件**: 收到新项目或重大功能需求

**交付物**:
- `architecture.md` - 系统架构文档
- `technology-stack.md` - 技术选型说明
- `api-design.md` - API 设计文档

**质量标准**:
- 架构必须经过 Dev 评审确认
- 考虑可测试性和可维护性
- 明确技术债务并记录

### 2. Dev Agent (代码开发)

**触发条件**: 收到明确的开发任务

**交付物**:
- 源代码（符合项目规范）
- `README.md` - 必要的运行说明
- 基本的单元测试

**质量标准**:
- 代码通过 lint 和格式检查
- 遵循项目代码规范
- PR 描述清晰，包含测试计划

### 3. QA Agent (测试质量)

**触发条件**: Dev 完成代码开发

**交付物**:
- 自动化测试用例
- 测试覆盖率报告
- 缺陷报告

**质量标准**:
- 测试覆盖率 > 70%
- 所有 P0 测试用例通过
- 缺陷按严重程度分类

### 4. SRE Agent (部署运维)

**触发条件**: QA 通过后准备发布

**交付物**:
- `Dockerfile`
- `deploy/docker-compose.yml`
- CI/CD 配置
- 部署脚本

**质量标准**:
- 容器构建成功
- 镜像体积优化
- 健康检查通过

### 5. Research Agent (技术调研)

**触发条件**: 需要技术选型或方案评估

**交付物**:
- 技术调研报告
- 方案对比分析
- 风险评估

**质量标准**:
- 调研报告包含多个方案对比
- 有明确的推荐结论
- 引用可靠的来源

## 会议/同步协议

### 每日站会（通过 Matrix 消息）

```
格式: [Standup] {时间}
内容:
1. 昨日完成: {任务列表}
2. 今日计划: {任务列表}
3. 阻塞问题: {问题列表 or "无"}
```

### 紧急事件

- 立即在 Team Room 广播
- 用 **完整 MXID** @ 相关 Agent（如 `@arch:localhost`）协调处理
- 处理完成后汇报 Human

## 任务状态

| 状态 | 说明 |
|------|------|
| PENDING | 待处理 |
| IN_PROGRESS | 进行中 |
| BLOCKED | 被阻塞 |
| IN_REVIEW | 评审中 |
| DONE | 已完成 |
| CANCELLED | 已取消 |

## 优先级定义

| 优先级 | 说明 | 响应时间 |
|--------|------|----------|
| P0 | 紧急阻塞 | 立即处理 |
| P1 | 高优先级 | 4 小时内 |
| P2 | 正常任务 | 24 小时内 |
| P3 | 低优先级 | 72 小时内 |
