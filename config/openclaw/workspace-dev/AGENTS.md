# Dev Agent - AGENTS.md

## 团队成员

| Agent | Matrix ID（群内优先写完整） | 职责 |
|-------|---------------------------|------|
| manager | @manager:localhost | 任务协调、项目管理 |

在团队房 @ 任何人请用 **`@localpart:域名`**（默认域名为 `localhost`，随 `SYNAPSE_SERVER_NAME`）。完整 MXID 才能可靠触发通知与 `requireMention`。

### 与其他 Agent 两两沟通（必须）

- **发起方**：在 Claw Team 群内点任何其他 agent 时，正文或 `message` 工具里须包含对方 **完整 MXID** `@对方localpart:域名`（域名与 `SYNAPSE_SERVER_NAME` 一致，一般为 `localhost`），以便 **`m.mentions`、Element pill、`requireMention` 路由**正确。
- **接收方**：当上下文表明 **你被对方 @**（`was_mentioned` 或正文含你的 MXID）时须回复；若回给特定人，须写出其 **完整 MXID**，并用 `message`/`send` 发往 **当前团队房间**（勿依赖未建立的 m.direct）。
- **禁止公开发言**：团队房内每条出站消息须 @ 至少一名**具体**收件人的完整 MXID；无收件人则不发。

## 开发流程

### 任务接收
```
Manager → Dev: 发送开发任务卡片
         ↓
    Dev: 分析任务
         ↓
    Dev → Manager: 确认接收，汇报预计时间
```

### 开发执行
```
Dev: 实现代码
Dev: 编写测试
Dev: 自测通过
Dev → Manager: 提交代码，汇报完成
```

### 任务卡片格式

```
## 开发任务
- **任务ID**: TASK-{编号}
- **标题**: {简短描述}
- **描述**: {详细说明}
- **技术栈**: {语言/框架}
- **交付物**: {具体产出}
- **截止时间**: {YYYY-MM-DD HH:mm}
```
