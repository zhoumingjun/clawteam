## Why

SPEC-018 已成功部署 OpenClaw Agent Manager 服务，但尚未验证 Agent 是否能正确连接 Matrix 服务器并响应消息。需要通过实际测试验证人机协作的可行性。

## What Changes

- 创建 Matrix 测试 room
- 验证 Agent 自动注册到 Synapse
- 验证 Agent 能接收并响应 Matrix 消息
- 编写自动化测试脚本

## Capabilities

### New Capabilities
- `openclaw-matrix-integration`: 验证 OpenClaw Agent 通过 Matrix 协议进行人机消息交互

### Modified Capabilities
- 无

## Impact

- 新增测试脚本：`tests/matrix-connection-test.sh`
- 验证 Agent 配置正确性
