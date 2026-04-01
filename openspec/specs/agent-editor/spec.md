## Purpose

提供 Web 界面编辑 Agent 的 Markdown 配置文件。

## Requirements

### Requirement: Agent 文件编辑
系统 SHALL 允许用户在 Web 界面编辑 Agent 的 Markdown 配置文件，保存后写回 `volumes/openclaw/{agent}/` 目录。

#### Scenario: 编辑并保存 Agent 文件
- **WHEN** 用户在 Agent 详情页编辑 SOUL.md 内容并点击保存
- **THEN** 系统将新内容写入 `volumes/openclaw/{agent}/SOUL.md`，页面显示保存成功

#### Scenario: 保存不存在的文件
- **WHEN** 客户端请求 `PUT /api/agents/nonexistent/SOUL.md`
- **THEN** 返回 404

### Requirement: Agent 文件更新 API
系统 SHALL 提供 `PUT /api/agents/{name}/{file}` 接口更新指定文件。

#### Scenario: 更新文件
- **WHEN** 客户端请求 `PUT /api/agents/manager/SOUL.md` 携带新内容
- **THEN** 文件被更新，返回 200

#### Scenario: 拒绝非法文件名
- **WHEN** 客户端请求 `PUT /api/agents/manager/../../etc/passwd`
- **THEN** 返回 400，拒绝路径遍历
