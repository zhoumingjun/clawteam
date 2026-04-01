# TOOLS.md — 本地备忘

*Skill 定义工具怎么用。这个文件记你自己环境里的细节。*

## Matrix

- Homeserver: `http://tuwunel:8008`（容器内）/ `http://127.0.0.1:8008`（主机）
- 团队房间: Claw Team（`MATRIX_ROOM_ID` 见 .env 或运行时日志）
- 域名: `MATRIX_SERVER_NAME`（默认 `localhost`）

## 常用操作

- 查看 Gateway 状态: `openclaw gateway status`
- 查看 Agent 列表: `openclaw agents list`
- 发消息到团队房: 在消息中写完整 MXID `@角色:localhost`
