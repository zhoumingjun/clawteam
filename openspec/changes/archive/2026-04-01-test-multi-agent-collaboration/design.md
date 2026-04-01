## Context

SPEC-018~020 完成了 OpenClaw Agent Manager 的部署和 Matrix 连接。需要验证多 Agent 协作能力。

## Goals / Non-Goals

**Goals:**
- 验证 Manager Agent 能接收 Human 指令
- 验证 Manager Agent 能拆解任务
- 验证 Agent 间消息传递

**Non-Goals:**
- 不测试完整的代码开发流程
- 不测试部署上线

## 关键发现

### OpenClaw Agent 架构
**发现**: OpenClaw Agent 不是传统 bot，不会自动响应 Matrix 消息。

Agent 与 Matrix 的关系：
- **Matrix channel**: 用于 Agent **发送消息**到 Matrix（通知、状态更新）
- **Gateway RPC**: Agent 的主控制接口，通过 `openclaw agent` 命令调用
- **消息接收**: Agent 不自动监听/响应 Matrix room 消息

### 验证结果
- Agent 已成功连接到 Matrix ✅
- Matrix channel 状态: running ✅
- 消息发送: 通过 `openclaw agent --deliver` 实现 ✅
- 消息接收: Agent 不自动响应 Matrix 消息 ❌

## 新测试方案

### 测试场景
使用 OpenClaw CLI 向 Agent 发送任务，通过 `--deliver` 标志将响应发送到 Matrix。

**流程**:
1. 使用 `openclaw agent --message "任务" --channel matrix --deliver` 发送任务
2. Agent 处理任务并返回响应
3. 响应通过 Matrix channel 发送到指定 room

### 验证方法
检查 Agent 响应是否通过 Matrix 发送。

## Open Questions

1. Dev Agent 是否需要单独部署？
2. Agent 间协作是否需要通过共享 Matrix room？
3. 当前架构是否满足 Claw Team 的实际需求？
