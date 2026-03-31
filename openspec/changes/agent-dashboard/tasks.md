## 1. 项目初始化

- [x] 1.1 创建 `dashboard/` 目录，初始化 Next.js 15 + Tailwind CSS + TypeScript
- [x] 1.2 创建 `dashboard/Dockerfile`（Node 22-slim, multi-stage build）

## 2. API 层

- [x] 2.1 实现 `src/lib/agents.ts` — `listAgents()`（扫描目录）、`getAgentFiles(name)`（读取所有 .md）、`updateAgentFile(name, file, content)`（写入文件，含路径遍历防护）
- [x] 2.2 实现 `src/lib/identity.ts` — `parseIdentity(markdown)` 解析 IDENTITY.md 的 Name/Creature/Vibe/Emoji/Avatar 字段
- [x] 2.3 实现 `src/app/api/agents/route.ts` — `GET /api/agents` 返回 agent 摘要列表
- [x] 2.4 实现 `src/app/api/agents/[name]/route.ts` — `GET /api/agents/{name}` 返回所有文件
- [x] 2.5 实现 `src/app/api/agents/[name]/[file]/route.ts` — `PUT /api/agents/{name}/{file}` 更新文件
- [x] 2.6 实现 `src/app/api/team/route.ts` — `GET /api/team` 和 `PUT /api/team`

## 3. 前端页面

- [x] 3.1 实现 `src/app/layout.tsx` — 全局布局（侧边栏：Agents / Team）
- [x] 3.2 实现首页 `src/app/page.tsx` — Agent 卡片网格（Emoji + Name + Creature + Vibe），点击跳转详情
- [x] 3.3 实现 `src/app/agents/[name]/page.tsx` — Agent 详情页（文件 Tab 切换 + textarea 编辑 + 保存按钮）
- [x] 3.4 实现 `src/app/team/page.tsx` — TEAM.md 查看/编辑页

## 4. 部署集成

- [x] 4.1 修改 `containers/openclaw/lib/agents-init.sh` — `deploy_workspaces()` 增加拷贝 TEAM.md 到 `$OPENCLAW_ROOT/TEAM.md`
- [x] 4.2 修改 `containers/docker-compose.yml` — 新增 dashboard 服务（build context、端口 3000、挂载 volumes/openclaw）
- [x] 4.3 修改 `Makefile` — 添加 `dashboard` 和 `dashboard-dev` 目标

## 5. 验证

- [x] 5.1 `make fresh` 部署成功（三个容器全部运行）
- [x] 5.2 访问 `http://127.0.0.1:3000` 看到 Agent 列表
- [x] 5.3 点击 Agent → 详情页正常，编辑保存成功
- [x] 5.4 访问 `/team` → TEAM.md 正常，编辑保存成功
