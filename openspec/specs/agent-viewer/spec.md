## Purpose

提供 Web 界面展示所有 Agent 的摘要信息和详情。

## Requirements

### Requirement: Agent 列表展示
系统 SHALL 在首页展示所有 Agent 的摘要卡片，数据从 `volumes/openclaw/{agent}/IDENTITY.md` 解析获取 Name、Emoji、Creature、Vibe 字段。

#### Scenario: 首页加载 Agent 列表
- **WHEN** 用户访问 `http://127.0.0.1:3000/`
- **THEN** 页面展示所有 Agent 卡片，每个卡片显示 Emoji、Name、Creature、Vibe

#### Scenario: 点击 Agent 卡片进入详情
- **WHEN** 用户点击某个 Agent 卡片
- **THEN** 跳转到 `/agents/{name}` 详情页

### Requirement: Agent 详情展示
系统 SHALL 在 Agent 详情页以 Tab 方式展示该 Agent 所有 .md 配置文件内容。

#### Scenario: 查看 Agent 详情
- **WHEN** 用户访问 `/agents/manager`
- **THEN** 页面展示 manager 的所有配置文件（IDENTITY.md, SOUL.md, AGENTS.md 等），默认显示 IDENTITY.md

#### Scenario: 切换文件 Tab
- **WHEN** 用户点击 "SOUL.md" Tab
- **THEN** 切换显示该 Agent 的 SOUL.md 内容

### Requirement: Agent 列表 API
系统 SHALL 提供 `GET /api/agents` 接口，扫描 `OPENCLAW_DATA_DIR` 返回所有 Agent 摘要。

#### Scenario: 获取 Agent 列表
- **WHEN** 客户端请求 `GET /api/agents`
- **THEN** 返回 JSON 数组，每项含 `name`、`emoji`、`creature`、`vibe` 字段

### Requirement: Agent 详情 API
系统 SHALL 提供 `GET /api/agents/{name}` 接口，返回指定 Agent 所有 .md 文件内容。

#### Scenario: 获取单个 Agent 详情
- **WHEN** 客户端请求 `GET /api/agents/manager`
- **THEN** 返回 JSON 对象，key 为文件名，value 为文件内容

#### Scenario: 请求不存在的 Agent
- **WHEN** 客户端请求 `GET /api/agents/nonexistent`
- **THEN** 返回 404
