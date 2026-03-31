## ADDED Requirements

### Requirement: 团队信息查看
系统 SHALL 在 `/team` 页面展示 TEAM.md 的内容。

#### Scenario: 查看团队信息
- **WHEN** 用户访问 `/team`
- **THEN** 页面展示 TEAM.md 的 Markdown 内容

### Requirement: 团队信息编辑
系统 SHALL 允许用户编辑 TEAM.md 并保存到 `volumes/openclaw/TEAM.md`。

#### Scenario: 编辑并保存团队信息
- **WHEN** 用户编辑 TEAM.md 内容并点击保存
- **THEN** 系统将新内容写入 `volumes/openclaw/TEAM.md`，显示保存成功

### Requirement: 团队信息 API
系统 SHALL 提供 `GET /api/team` 和 `PUT /api/team` 接口。

#### Scenario: 获取团队信息
- **WHEN** 客户端请求 `GET /api/team`
- **THEN** 返回 TEAM.md 的文本内容

#### Scenario: 更新团队信息
- **WHEN** 客户端请求 `PUT /api/team` 携带新内容
- **THEN** 文件被更新，返回 200
