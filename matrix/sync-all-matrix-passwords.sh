#!/bin/bash
# 通过标准 Client API：登录或 registration_token 注册，确保 Human + 各 Agent 存在。
# Tuwunel 无 Synapse admin register_new_matrix_user；已存在用户时本脚本无法改密（需 make fresh）。
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

DC=(docker compose -f deploy/docker-compose.yml --env-file .env)
if ! "${DC[@]}" ps --format "{{.Names}}" 2>/dev/null | grep -qx "clawteam-tuwunel"; then
  echo "Tuwunel 容器未运行，请先 make up"
  exit 1
fi

SYNAPSE_PORT="$(get_env_val SYNAPSE_PORT)"; SYNAPSE_PORT="${SYNAPSE_PORT:-8008}"
HS="http://127.0.0.1:${SYNAPSE_PORT}"
REG="$(get_env_val SYNAPSE_REGISTRATION_SHARED_SECRET)"; REG="${REG:-a-secret-key-change-in-production}"
ENSURE="${ROOT}/platform/matrix-ensure-user.py"

reg() {
  local user="$1" pass="$2"
  echo "同步 @${user} …"
  if python3 "$ENSURE" "$HS" "$user" "$pass" "$REG"; then
    return 0
  fi
  echo "  警告: @${user} 登录/注册失败（若用户已存在且密码与 .env 不一致，请 make fresh）" >&2
  return 0
}

HU="$(get_env_val HUMAN_USERNAME)"; HU="${HU:-human}"
HP="$(get_env_val HUMAN_PASSWORD)"; [ -n "$HP" ] || { echo "缺少 HUMAN_PASSWORD"; exit 1; }
reg "$HU" "$HP"

for pair in \
  arch:ARCH_PASSWORD \
  dev:DEV_PASSWORD \
  manager:MANAGER_PASSWORD \
  qa:QA_PASSWORD \
  sre:SRE_PASSWORD \
  research:RESEARCH_PASSWORD; do
  u="${pair%%:*}"
  var="${pair##*:}"
  pw="$(get_env_val "$var")"
  if [ -z "$pw" ]; then
    echo "跳过 $u（未设置 $var）"
    continue
  fi
  reg "$u" "$pw"
done

echo "完成。"
