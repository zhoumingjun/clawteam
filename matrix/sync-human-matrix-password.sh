#!/bin/bash
# 确保 Human 用户存在于 Tuwunel（登录或 registration_token 注册）。
# 已存在且密码与 .env 不一致时无法覆盖，请 make fresh 或在客户端修改。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

if [ ! -f .env ]; then
  echo "缺少 .env"
  exit 1
fi

get_env_val() {
  local key="$1"
  grep -E "^${key}=" .env 2>/dev/null | head -1 | cut -d= -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"\(.*\)"$/\1/;s/^'"'"'\(.*\)'"'"'$/\1/'
}

HUMAN_USERNAME="$(get_env_val HUMAN_USERNAME)"
HUMAN_PASSWORD="$(get_env_val HUMAN_PASSWORD)"
HUMAN_USERNAME="${HUMAN_USERNAME:-human}"
if [ -z "$HUMAN_PASSWORD" ]; then
  echo "请在 .env 中设置 HUMAN_PASSWORD"
  exit 1
fi

DC=(docker compose -f deploy/docker-compose.yml --env-file .env)
if ! "${DC[@]}" ps --format "{{.Names}}" 2>/dev/null | grep -qx "clawteam-tuwunel"; then
  echo "Tuwunel 容器未运行，请先 make up 或 ./platform/deploy.sh"
  exit 1
fi

SYNAPSE_PORT="$(get_env_val SYNAPSE_PORT)"; SYNAPSE_PORT="${SYNAPSE_PORT:-8008}"
HS="http://127.0.0.1:${SYNAPSE_PORT}"
REG="$(get_env_val SYNAPSE_REGISTRATION_SHARED_SECRET)"; REG="${REG:-a-secret-key-change-in-production}"

echo "确保 Matrix 用户 @${HUMAN_USERNAME} 存在于 Tuwunel…"
python3 "${ROOT}/platform/matrix-ensure-user.py" "$HS" "$HUMAN_USERNAME" "$HUMAN_PASSWORD" "$REG"

echo "完成。请用 Element 登录：用户 ${HUMAN_USERNAME}，密码见 .env 的 HUMAN_PASSWORD。"
