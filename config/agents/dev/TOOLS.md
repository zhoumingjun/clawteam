# TOOLS.md — 本地备忘

*Skill 定义工具怎么用。这个文件记你自己环境里的细节。*

## Matrix

- Homeserver: `http://tuwunel:8008`（容器内）/ `http://127.0.0.1:8008`（主机）
- 团队房间: Claw Team
- 域名: `MATRIX_SERVER_NAME`（默认 `localhost`）

## 常用操作

- 运行测试: `pytest` / `npm test`
- Lint: `ruff check .` / `eslint .`
- Git 操作: `git status`, `git diff`, `git log --oneline -10`
- 依赖安装: `uv sync` / `npm install`
