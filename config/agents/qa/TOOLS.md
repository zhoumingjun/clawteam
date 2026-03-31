# TOOLS.md — 本地备忘

*Skill 定义工具怎么用。这个文件记你自己环境里的细节。*

## Matrix

- Homeserver: `http://tuwunel:8008`（容器内）/ `http://127.0.0.1:8008`（主机）
- 团队房间: Claw Team
- 域名: `MATRIX_SERVER_NAME`（默认 `localhost`）

## 常用操作

- 运行测试: `pytest -v` / `npm test`
- 覆盖率: `pytest --cov` / `nyc npm test`
- Lint: `ruff check .` / `eslint .`
- E2E 测试: `tests/e2e/` 下的脚本
