## Context

SPEC-018~020 完成了 OpenClaw Agent Manager 的部署和 Matrix 连接。现在需要验证多 Agent 协作能力。

## Goals / Non-Goals

**Goals:**
- 验证 Manager Agent 能接收 Human 指令
- 验证 Manager Agent 能拆解任务
- 验证 Agent 间消息传递

**Non-Goals:**
- 不测试完整的代码开发流程
- 不测试部署上线

## Decisions

### 1. 测试场景
**场景**: Human 向 Manager 发送"创建一个 hello world REST API"任务

**预期流程**:
1. Human → Manager: 发送任务
2. Manager: 分析任务，拆解为子任务
3. Manager → Dev: 分配开发子任务
4. Dev → Manager: 返回开发结果
5. Manager → Human: 汇报完成

### 2. 测试方式
**决定**: 通过 Matrix room 消息传递

**理由**:
- Agent 已接入 Matrix
- 便于观察消息流转
- 符合实际使用场景

### 3. 验证方法
检查 Matrix room 消息历史，确认：
- Manager 收到任务
- Manager 发送任务分配消息给 Dev
- Dev 响应任务

## Open Questions

- Dev Agent 是否已部署？（当前只有 Manager Agent）
- 如果只有 Manager，是否先验证 Manager 的任务拆解能力？
