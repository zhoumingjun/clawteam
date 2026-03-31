#!/bin/bash
# 共享变量与工具函数

OPENCLAW_ROOT="${OPENCLAW_ROOT:-/root/.openclaw}"
OPENCLAW_SOURCE="${OPENCLAW_SOURCE:-/app/.openclaw}"
MATRIX_HOMESERVER_URL="${MATRIX_HOMESERVER_URL:-http://tuwunel:8008}"
MATRIX_ENSURE_USER_PY="${MATRIX_ENSURE_USER_PY:-/app/openclaw/lib/matrix-ensure-user.py}"
MATRIX_SERVER_NAME="${MATRIX_SERVER_NAME:-localhost}"
HUMAN_USERNAME="${HUMAN_USERNAME:-human}"
AGENTS="arch dev manager qa sre research"
PASSWORDS_FILE="$OPENCLAW_ROOT/.agent-passwords"
TOKENS_FILE="$OPENCLAW_ROOT/.agent-tokens"
OPENCLAW_JSON="$OPENCLAW_ROOT/openclaw.json"
MATRIX_ROOM_CACHE="$OPENCLAW_ROOT/.matrix-team-room-id"
TEAM_ROOM_NAME="${PROJECT_NAME:-${TEAM_ROOM_NAME:-Claw Team}}"
INVITES_DONE_FILE="$OPENCLAW_ROOT/.team-room-invites-done"

log_info() { echo "[openclaw] $*"; }
log_warn() { echo "[openclaw] WARNING: $*" >&2; }

json_get() {
  local key="$1"
  node -e "try{const d=JSON.parse(require('fs').readFileSync(0,'utf8')); console.log(d['${key}']||'');}catch(e){console.log('');}"
}
