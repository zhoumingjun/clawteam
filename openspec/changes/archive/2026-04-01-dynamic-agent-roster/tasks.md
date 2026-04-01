## 1. 创建 team.yaml

- [x] 1.1 在 `config/agents/` 创建 `team.yaml`（agents: 7 个角色含 manager 和 product；projects: 空列表占位；collaboration: 沟通方式/任务分发/决策机制/记忆与状态）
- [x] 1.2 更新 entrypoint 的 copy 逻辑：将 `team.yaml` 从 `/app/.openclaw/` 拷贝到 `/root/.openclaw/`

## 2. team.yaml 解析脚本

- [x] 2.1 创建 `containers/openclaw/lib/parse-team-yaml.py`：解析 team.yaml，输出 AGENTS（空格分隔的 agent name 列表）和 OC_ROLES（JSON 数组）
- [x] 2.2 更新 `common.sh`：删除硬编码 `AGENTS="..."`，改为调用 parse-team-yaml.py 从 `/root/.openclaw/team.yaml` 动态读取

## 3. 重构 matrix-init.sh

- [x] 3.1 将 `agent_env_password_var()` 从 case 枚举改为动态转换
- [x] 3.2 将 `create_team_room_if_needed()` 改为使用 human token
- [x] 3.3 将 `invite_all_team_members()` 改为使用 human token

## 4. 重构 agents-init.sh

- [x] 4.1 将 `deploy_workspaces()` 的硬编码 spec 改为从 AGENTS 动态生成（加上 `main:default` 固定映射）
- [x] 4.2 将 `register_openclaw_agents()` 的硬编码 spec 改为从 AGENTS 动态生成

## 5. 重构 config-gen.sh

- [x] 5.1 将 `generate_openclaw_json()` 中的硬编码 ROLES 改为从环境变量 `OC_ROLES` 读取
- [x] 5.2 将 `patch_bindings_if_room()` 中的硬编码 ROLES 改为从环境变量 `OC_ROLES` 读取
- [x] 5.3 在调用这两个函数前，由 common.sh 导出 `OC_ROLES` 环境变量

## 6. TEAM.md 渲染脚本

- [x] 6.1 创建 `containers/openclaw/lib/render-team-md.py`：从 team.yaml 渲染 TEAM.md（成员表 + collaboration 各段落）
- [x] 6.2 在 entrypoint 中调用渲染脚本，输出到 `/root/.openclaw/TEAM.md`
- [x] 6.3 删除 `config/agents/TEAM.md`（改为自动生成，不再手写）

## 7. 新增 product agent

- [x] 7.1 创建 `config/agents/product/` 目录，编写 IDENTITY.md（Name: Product, Emoji: 📝）
- [x] 7.2 编写 product 的 SOUL.md（需求分析、Spec 编写、验收标准、优先级排序）
- [x] 7.3 编写 product 的 AGENTS.md（引用 TEAM.md）
- [x] 7.4 编写 product 的 BOOTSTRAP.md（引用 TEAM.md 发现团队成员）
- [x] 7.5 编写 product 的 HEARTBEAT.md、MEMORY.md、TOOLS.md、USER.md

## 8. 更新已有 agent 配置

- [x] 8.1 更新所有 agent 的 AGENTS.md：删除硬编码成员列表，改为引用 TEAM.md
- [x] 8.2 更新所有 agent 的 BOOTSTRAP.md：删除硬编码 `@manager:localhost`，改为引用 TEAM.md
- [x] 8.3 更新所有 agent 的 USER.md：删除对特定 agent 的硬编码引用
- [x] 8.4 更新所有 agent 的 SOUL.md：删除对特定 agent 名字的硬编码引用，改为通用角色描述
- [x] 8.5 更新 `config/agents/default/` 保持独立（Gateway 入口角色，不引用特定 agent）

## 9. 环境变量更新

- [x] 9.1 更新 `.env.example`：添加 `PRODUCT_PASSWORD`
- [x] 9.2 更新 `.env`：添加 `PRODUCT_PASSWORD`

## 10. 测试更新

- [x] 10.1 更新 `tests/test_repo_layout.py`：agents 元组添加 "product"
- [x] 10.2 更新 `tests/e2e/verify-matrix-pairwise-config.sh`：ROLES 数组添加 product
- [x] 10.3 更新 `tests/e2e/e2e-matrix-mentions.sh`：roles 元组添加 product
- [x] 10.4 更新 `tests/e2e/e2e-matrix-agents-all.sh` 和相关 e2e 脚本

## 11. 文档更新

- [x] 11.1 更新 `README.md`：agent 角色表添加 product
- [x] 11.2 更新 `CLAUDE.md`：项目状态
- [x] 11.3 更新 `docs/` 下相关文档

## 12. 集成验证

- [x] 12.1 运行 `make fresh` 验证全新部署成功（所有 agent 含 product 注册正常）
- [x] 12.2 运行 `make test` 验证测试通过
- [x] 12.3 验证增加新 agent 只需编辑 team.yaml + 新建目录（不改任何脚本）
