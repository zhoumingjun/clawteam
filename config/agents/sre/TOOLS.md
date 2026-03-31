# TOOLS.md — 本地备忘

*Skill 定义工具怎么用。这个文件记你自己环境里的细节。*

## Matrix

- Homeserver: `http://tuwunel:8008`（容器内）/ `http://127.0.0.1:8008`（主机）
- 团队房间: Claw Team
- 域名: `MATRIX_SERVER_NAME`（默认 `localhost`）

## 常用操作

- 容器状态: `docker compose -f containers/docker-compose.yml --env-file .env ps`
- 容器日志: `docker compose -f containers/docker-compose.yml --env-file .env logs -f`
- 健康检查: `curl -sf http://127.0.0.1:8008/_matrix/client/versions`
- 部署: `make fresh` / `make deploy`
- 诊断: `devops/stack-check.sh`
