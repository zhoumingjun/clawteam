## Context

当前 agent 名单硬编码在 6+ 个位置。增删一个角色要改 50+ 个文件。核心问题是没有 single source of truth。

关键文件现状：
- `common.sh`: `AGENTS="arch dev manager qa sre research"` 硬编码
- `matrix-init.sh`: `agent_env_password_var()` 用 case 枚举所有 agent；建群/邀请用 manager token
- `agents-init.sh`: workspace 和注册映射硬编码为 `spec="arch:arch dev:dev manager:manager ..."`
- `config-gen.sh`: 两处 `ROLES = ['arch','dev','manager','qa','sre','research']` 硬编码在 Node.js 中
- 每个 agent 的 USER.md/AGENTS.md/BOOTSTRAP.md 手写互相引用其他 agent

架构原则：
- `config/` 是项目代码（只读模板，git tracked），不允许运行时修改
- `volumes/openclaw/` 是运行时数据（读写卷，gitignored）
- config 内容通过 entrypoint 首次部署时 copy 到 volumes

## Goals / Non-Goals

**Goals:**
- `team.yaml` 作为唯一 agent 名单和协作规则定义（single source of truth）
- 部署脚本全部从 `team.yaml` 动态读取
- 增删 agent 只需：编辑 `team.yaml` + 增删 `config/agents/<name>/` 目录
- 新增 product 角色
- 每个 agent 的配置文件只描述自己，团队信息统一在 TEAM.md（从 team.yaml 渲染）
- 每个 agent 的 AGENTS.md 引用 TEAM.md，不重复罗列其他成员

**Non-Goals:**
- 不做 Web UI 管理 agent 名单（未来 dashboard 功能）
- 不做运行时热更新 agent（需要重启容器）
- 不改变 OpenClaw Gateway 本身的 API

## Decisions

### D1: team.yaml 放在 config/agents/ 下，走已有的 copy 机制

**选择**: `config/agents/team.yaml`，随 `config/agents/` 一起挂载到 `/app/.openclaw/`（只读），entrypoint 首次部署时拷贝到 `/root/.openclaw/team.yaml`。脚本从 `/root/.openclaw/team.yaml` 读取。

**替代方案**:
- 放在项目根目录单独挂载 → 破坏已有的 config→copy→runtime 模式
- 放在 `.env` 里用逗号分隔 → 无法表达结构化信息

**理由**: 与 `config/agents/` 走同一个挂载和 copy 流程，不需要改 docker-compose.yml。

### D2: team.yaml 结构 — 三个顶级字段

**选择**:
```yaml
agents:         # 列表：谁在团队里（不含 default）
projects:       # 列表：做什么项目
collaboration:  # 字典：怎么协作（key=标题，value=说明文本）
```

- `agents` 列出所有 agent（manager, product, arch, dev, qa, sre, research），每个有 name/role/emoji
- `default` agent 不在列表中（它是 Gateway 内置角色，有独立配置目录 `config/agents/default/`）
- `projects` 列出项目信息（name, room, repo, path），当前 Phase 1 先支持单项目
- `collaboration` 是完全自定义的字典，每个 key 是标题，value 是说明文本，渲染到 TEAM.md

**替代方案**:
- collaboration 用固定结构（protocols/notes/channel）→ 不够灵活
- default 和 manager 合并 → 两者职责不同，应独立

**理由**: 三个字段各司其职，collaboration 自由定制不限制用户。

### D3: 用 Python 解析 YAML（不引入新依赖）

**选择**: 容器内已有 Python 3，用一个小 Python 脚本解析 team.yaml 输出 shell 变量

**替代方案**:
- 用 `yq` → 需要额外安装
- 纯 shell 解析 → 脆弱

**理由**: Python 3 已在容器内。team.yaml 格式简单，不需要 PyYAML，用简单的正则或逐行解析即可。

### D4: 建群和邀请改用 human token

**选择**: 用 human 用户的 token 创建房间和邀请成员

**理由**: human 账号始终存在，不依赖任何特定 agent。

### D5: password 变量命名统一为 `<UPPER_NAME>_PASSWORD`

**选择**: 动态转换 agent name → 大写 + `_PASSWORD`，如 `product → PRODUCT_PASSWORD`

**理由**: `echo "$agent" | tr 'a-z' 'A-Z'` 即可，增加 agent 无需改代码。

### D6: config-gen.sh 通过环境变量传入 ROLES

**选择**: shell 脚本解析 team.yaml 后，将 agent 列表作为 JSON 数组通过环境变量传入 Node.js

**理由**: 不需要 Node.js 侧的 YAML 解析依赖。

### D7: TEAM.md 从 team.yaml 渲染

**选择**: entrypoint 中调用渲染脚本，从 team.yaml 生成 TEAM.md 到 `volumes/openclaw/TEAM.md`。内容包含：
- 团队成员表（从 agents 渲染）
- 各 collaboration 段落（从 collaboration 的 key/value 渲染）

每个 agent 的 AGENTS.md 只写"团队信息参见 TEAM.md"，不重复罗列成员。

**理由**: 增删 agent 时只改 team.yaml，TEAM.md 自动更新，所有 agent 通过引用自动获取最新团队信息。

## Risks / Trade-offs

- **[YAML 解析]** → 无 PyYAML。缓解: 格式极简，Python 正则可解析
- **[渲染脚本]** → 新增一个脚本。缓解: 逻辑简单，仅在部署时运行
- **[向后兼容]** → .env 密码变量需改名。缓解: `deploy.sh --fresh` 处理；文档注明迁移
- **[TEAM.md 覆盖]** → 每次部署重新渲染会覆盖手动修改。缓解: 明确 TEAM.md 是生成文件，手动修改应改 team.yaml
