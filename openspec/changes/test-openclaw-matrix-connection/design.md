## Context

Claw Team 项目已部署 OpenClaw Agent Manager 服务（SPEC-018），需要验证 Agent 能通过 Matrix 协议与人进行消息交互。

## Goals / Non-Goals

**Goals:**
- 验证 Agent 能连接 Synapse Matrix 服务器
- 验证 Agent 在 Matrix room 中能接收并响应消息
- 编写自动化测试脚本

**Non-Goals:**
- 不测试 Agent 之间的协作
- 不测试消息的持久化存储
- 不进行性能测试

## Decisions

### 1. Matrix 集成方式
**决定**: 使用 OpenClaw 内置 `@openclaw/matrix` 插件

**理由**:
- OpenClaw 已内置 Matrix 支持（需要启用）
- 提供完整的 channel 管理功能
- 支持 Docker 网络环境

### 2. 配置步骤
1. 在 docker-compose.yml 中添加插件启用和配置（通过 environment 或 volume）
2. 在容器内执行 `openclaw plugins enable matrix`
3. 配置 `openclaw config set channels.matrix.allowPrivateNetwork true`
4. 执行 `openclaw channels add --channel matrix --homeserver http://synapse:8008 --user-id @openclaw-agent:localhost --password <password>`
5. 重启容器使配置生效

### 3. 验证方法
**决定**: 使用 `openclaw channels status` 检查连接状态

**理由**:
- 命令返回 `running` 表示连接成功
- 便于自动化测试

## Implementation Findings

### OpenClaw Matrix 插件配置要求
- 插件 ID: `matrix`
- Homeserver URL 必须是 `https://` 或 `localhost/127.0.0.1`
- Docker 网络中需要设置 `allowPrivateNetwork: true`
- 用户需要先在 Synapse 注册（可通过 `/_matrix/client/r0/register`）

### Docker 网络说明
- Synapse 服务名 `synapse` 在 Docker 网络中可解析
- 需要 `allowPrivateNetwork: true` 绕过 OpenClaw 的 URL 验证

## Risks / Trade-offs

- **风险**: Matrix 插件加密引导失败（warning）
  - **影响**: 不影响基本消息收发功能
  - **缓解**: 暂不需要端到端加密

## Migration Plan

1. 创建 Agent 用户 `openclaw-agent`
2. 在容器内启用并配置 Matrix 插件
3. 验证连接状态
4. 更新 docker-compose.yml 添加环境变量配置
5. 编写测试脚本
