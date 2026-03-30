## Why

SPEC-019 验证了 OpenClaw Agent 能成功连接 Matrix，但当前配置（启用 matrix 插件、添加 channel 配置）在容器重启后会丢失。需要将配置固化到持久化文件中。

## What Changes

- 在 `configs/agents/manager/` 中添加 OpenClaw 配置文件
- 添加初始化脚本 `scripts/openclaw-matrix-init.sh`
- 更新 `docker-compose.yml` 添加必要的 environment 或 volume 配置

## Capabilities

### New Capabilities
- `openclaw-matrix-persistence`: OpenClaw Agent Matrix channel 配置持久化

### Modified Capabilities
- 无

## Impact

- 修改 `configs/agents/manager/` 目录
- 新增 `scripts/openclaw-matrix-init.sh`
- 更新 `docker-compose.yml`
