#!/usr/bin/env bash
# 部署验收检查：容器运行 + Tuwunel HTTP + 团队房 + tokens
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck disable=SC1091
if [[ -f .env ]]; then set -a; source .env; set +a; fi
PORT="${MATRIX_PORT:-8008}"

err() { echo "stack-check: ERROR: $*" >&2; exit 1; }

docker info >/dev/null 2>&1 || err "Docker 不可用"

names="$(docker ps --format '{{.Names}}' 2>/dev/null || true)"
echo "$names" | grep -Fxq "clawteam-tuwunel"  || err "clawteam-tuwunel 未运行（请先 make deploy）"
echo "$names" | grep -Fxq "clawteam-openclaw"  || err "clawteam-openclaw 未运行"

curl -sf "http://127.0.0.1:${PORT}/_matrix/client/versions" >/dev/null \
  || err "Tuwunel 未响应 http://127.0.0.1:${PORT}"

[[ -f "${ROOT}/volumes/openclaw/.matrix-team-room-id" ]] || err "缺少团队房 ID 文件"
[[ -f "${ROOT}/volumes/openclaw/.agent-tokens" ]]        || err "缺少 agent tokens 文件"

echo "stack-check: OK (tuwunel :${PORT}, openclaw running, room + tokens present)"
