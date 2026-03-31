# Claw Team 用户手册

**完整版见 [docs/user-manual.md](docs/user-manual.md)。**

---

## 极简步骤

1. `cp .env.example .env` 并填写 `ANTHROPIC_API_KEY`。
2. `make fresh`。
3. Element 连接 `http://127.0.0.1:8008`，用户 `@human:localhost`，密码见 `.env`。
4. 在团队房内 **@ 对应 Agent** 再发消息。

异常时：`make fresh` 重新部署即可。

**开发/手测**：[docs/developer-handbook.md](docs/developer-handbook.md)。
