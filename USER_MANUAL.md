# Claw Team 用户手册

**完整版（含运行原理、Element 协作、排错）见 [docs/user-manual.md](docs/user-manual.md)。**

---

## 极简步骤

1. `cp .env.example .env` 并填写 `ANTHROPIC_API_KEY`、`HUMAN_PASSWORD`、各 `*_PASSWORD`。  
2. `make fresh`（或 `./platform/deploy.sh --fresh`）。  
3. Element 连接 `http://127.0.0.1:8008`，用户 `@human:localhost`，密码见 `.env`。  
4. 在团队房内 **@ 对应 Agent** 再发消息（`requireMention` 下不 @ 通常无回复）。

异常时：`bash matrix/sync-all-matrix-passwords.sh` → `bash matrix/matrix-bootstrap-team-room.sh` → `docker compose -f deploy/docker-compose.yml --env-file .env restart openclaw`。

**开发/手测**：[docs/developer-handbook.md](docs/developer-handbook.md)。
