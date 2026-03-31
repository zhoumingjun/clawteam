#!/usr/bin/env bash
# 部署验收前检查：Tuwunel / OpenClaw 容器与 HTTP 就绪（项目根执行）。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck disable=SC1091
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi
PORT="${SYNAPSE_PORT:-8008}"

err() { echo "stack-check: ERROR: $*" >&2; exit 1; }

if ! docker info >/dev/null 2>&1; then
  err "Docker 不可用"
fi

names="$(docker ps --format '{{.Names}}' 2>/dev/null || true)"
echo "$names" | grep -Fxq "clawteam-tuwunel" || err "clawteam-tuwunel 未运行（请先 make deploy / make up）"
echo "$names" | grep -Fxq "clawteam-openclaw" || err "clawteam-openclaw 未运行"

if ! curl -sf "http://127.0.0.1:${PORT}/_matrix/client/versions" >/dev/null; then
  err "Tuwunel 未响应 http://127.0.0.1:${PORT}/_matrix/client/versions"
fi

ROOM_FILE="${ROOT}/volumes/openclaw/.matrix-team-room-id"
[[ -f "$ROOM_FILE" ]] || err "缺少团队房 ID 文件 ${ROOM_FILE}（OpenClaw 是否完成启动？）"
TOK="${ROOT}/volumes/openclaw/.agent-tokens"
[[ -f "$TOK" ]] || err "缺少 ${TOK}"

echo "stack-check: OK (tuwunel :${PORT}, openclaw running, room + tokens present)"
