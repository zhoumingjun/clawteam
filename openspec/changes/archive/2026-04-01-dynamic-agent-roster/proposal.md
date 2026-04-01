## Why

Agent 名单硬编码在 6+ 个位置（common.sh、agents-init.sh、config-gen.sh、matrix-init.sh、.env、每个 agent 的 USER.md/AGENTS.md/BOOTSTRAP.md），增删一个角色需要修改 50+ 个文件。这让团队组成变成了一次性配置而非可演进的能力。AI Software Factory 必须支持用户自由增删角色。

## What Changes

- **BREAKING**: 新增 `team.yaml` 作为 agent 名单的 single source of truth，取代所有硬编码
- 部署脚本（common.sh、matrix-init.sh、agents-init.sh、config-gen.sh）改为从 `team.yaml` 动态读取 agent 列表
- `agent_env_password_var()` 改为通用映射（`<NAME>_PASSWORD`），不再 case 枚举
- `matrix-init.sh` 中建群/邀请逻辑改为使用 human token（不再依赖特定 agent）
- config-gen.sh 中 `ROLES` 数组从 `team.yaml` 动态生成
- Agent 配置模板中的互相引用（USER.md、AGENTS.md、BOOTSTRAP.md）支持从 `team.yaml` 渲染
- TEAM.md 从 `team.yaml` 自动生成
- 在此基础上完成角色调整：删除 manager、default 使用 manager 内容、新增 product
- .env 密码变量统一命名 `<UPPER_NAME>_PASSWORD`

## Capabilities

### New Capabilities
- `team-config`: `team.yaml` 格式定义、解析脚本、校验逻辑
- `dynamic-deploy-scripts`: 部署脚本从 team.yaml 动态读取，不再硬编码 agent 名单
- `agent-template-render`: Agent 配置文件中的互相引用从 team.yaml 渲染，TEAM.md 自动生成
- `product-agent`: 新增 Product 角色（需求分析、Spec 编写、验收标准）

### Modified Capabilities

## Impact

- **部署脚本**: `containers/openclaw/lib/` 下 4 个 shell 脚本大幅重构
- **环境变量**: `.env` / `.env.example` 密码变量命名变更（MANAGER_PASSWORD → PRODUCT_PASSWORD）
- **Agent 配置**: `config/agents/` 目录结构变化（删 manager、加 product、改 default）
- **所有 Agent 的模板文件**: USER.md、AGENTS.md、BOOTSTRAP.md 需适配新的渲染机制
- **测试**: `tests/` 中 agent 名单相关测试需更新
- **文档**: README.md、docs/ 中 agent 引用需更新
