#!/usr/bin/env bash
# E2E：以 human 在团队房 @manager，校验随后**任一团队 agent** 出站消息含 matrix.to + 干净 m.mentions（含 @dev/@qa）。
# 说明：多账号同群时 OpenClaw 偶发用非 manager 账号发出回复，故发送者不强制为 manager；agent 间见 e2e-matrix-manager-ping-dev.sh（实为 sre→@dev）。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/.env"

MX_SRV="${MATRIX_SERVER_NAME:-localhost}"
export E2E_MX_SRV="$MX_SRV"
export E2E_MSG_BODY="@manager:${MX_SRV} [e2e-mention] 请只发一条回复，正文必须同时包含完整 Matrix ID @dev:${MX_SRV} 与 @qa:${MX_SRV}（不要用单独的短 @dev / @qa）。不要分多条。"

SYNAPSE="${MATRIX_URL:-http://127.0.0.1:${MATRIX_PORT:-8008}}"
ROOM_FILE="${ROOT}/volumes/openclaw/.matrix-team-room-id"
ROOM_RAW="$(tr -d '[:space:]' <"$ROOM_FILE")"
ROOM_ENC="$(python3 -c "import urllib.parse; print(urllib.parse.quote('$ROOM_RAW', safe=''))")"

export E2E_MATRIX_USER="${HUMAN_USERNAME:-human}"
export E2E_MATRIX_PASS="${HUMAN_PASSWORD:?HUMAN_PASSWORD missing}"

LOGIN_PAYLOAD="$(python3 <<'PY'
import json, os
print(
    json.dumps(
        {
            "type": "m.login.password",
            "identifier": {"type": "m.id.user", "user": os.environ["E2E_MATRIX_USER"]},
            "password": os.environ["E2E_MATRIX_PASS"],
        }
    )
)
PY
)"

LOGIN="$(curl -sf -X POST "${SYNAPSE}/_matrix/client/v3/login" \
  -H 'Content-Type: application/json' \
  -d "$LOGIN_PAYLOAD")" || {
  echo "e2e-matrix-mentions: Matrix 登录失败（Synapse 是否在本机 ${MATRIX_PORT:-8008} 监听？）" >&2
  exit 2
}

export E2E_LOGIN_JSON="$LOGIN"
TOKEN="$(python3 -c "import json,os; print(json.loads(os.environ['E2E_LOGIN_JSON'])['access_token'])")"

TXN="e2e-mention-$(date +%s)"
SEND_PAYLOAD="$(python3 <<'PY'
import json, os
print(json.dumps({"msgtype": "m.text", "body": os.environ["E2E_MSG_BODY"]}))
PY
)"

SEND="$(curl -sf -X PUT "${SYNAPSE}/_matrix/client/v3/rooms/${ROOM_ENC}/send/m.room.message/${TXN}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H 'Content-Type: application/json' \
  -d "$SEND_PAYLOAD")" || {
  echo "e2e-matrix-mentions: 发消息失败" >&2
  exit 3
}

export E2E_SEND_JSON="$SEND"
TRIG="$(python3 -c "import json,os; print(json.loads(os.environ['E2E_SEND_JSON'])['event_id'])")"
printf 'e2e-matrix-mentions: trigger %s (server=%s)\n' "$TRIG" "$MX_SRV"

export E2E_TRIG_ID="$TRIG"
TRIG_ENC="$(python3 -c "import urllib.parse, os; print(urllib.parse.quote(os.environ['E2E_TRIG_ID'], safe=''))")"
EV_URL="${SYNAPSE}/_matrix/client/v3/rooms/${ROOM_ENC}/event/${TRIG_ENC}"
TRIG_TS="$(curl -sf "$EV_URL" -H "Authorization: Bearer $TOKEN" | python3 -c "import json,sys; print(json.load(sys.stdin)['origin_server_ts'])")" || {
  echo "e2e-matrix-mentions: 无法拉取触发事件时间戳" >&2
  exit 3
}

export E2E_TRIG_TS="$TRIG_TS"
export E2E_TOKEN="$TOKEN"
export E2E_ROOM_ENC="$ROOM_ENC"
export E2E_SYNAPSE="$SYNAPSE"

MAX_WAIT=240
STEP=5
elapsed=0
PASS_JSON=""
while [[ "$elapsed" -lt "$MAX_WAIT" ]]; do
  sleep "$STEP"
  elapsed=$((elapsed + STEP))
  RAW="$(curl -sf "${E2E_SYNAPSE}/_matrix/client/v3/rooms/${E2E_ROOM_ENC}/messages?dir=b&limit=120" \
    -H "Authorization: Bearer ${E2E_TOKEN}")" || continue
  [[ -n "$RAW" ]] || continue
  if OUT="$(printf '%s' "$RAW" | python3 -c "
import json, os, sys
raw = json.load(sys.stdin)
cut = int(os.environ['E2E_TRIG_TS'])
srv = os.environ['E2E_MX_SRV']
roles = ('manager', 'product', 'arch', 'dev', 'qa', 'sre', 'research')
allowed = {'@' + r + ':' + srv for r in roles}
need = {'@dev:' + srv, '@qa:' + srv}
BAD = {'@q:' + srv, '@de:' + srv, '@arc:' + srv}
union = set()
has_matrix_to = False
events = []
senders = set()
for ev in raw.get('chunk') or []:
    if ev.get('type') != 'm.room.message':
        continue
    sender = ev.get('sender') or ''
    if sender not in allowed:
        continue
    ts = ev.get('origin_server_ts') or 0
    if ts <= cut:
        continue
    c = ev.get('content') or {}
    fb = c.get('formatted_body') or ''
    mm = c.get('m.mentions') or {}
    u = mm.get('user_ids') or []
    if any(x in BAD for x in u):
        sys.exit(1)
    if u:
        union |= set(u)
        if 'matrix.to/#/' in fb:
            has_matrix_to = True
        events.append(ev.get('event_id'))
        senders.add(sender)
if need <= union and has_matrix_to and events:
    print(json.dumps({'ok': True, 'event_ids': events, 'union': sorted(union), 'senders': sorted(senders)}))
    sys.exit(0)
sys.exit(1)
")"; then
    PASS_JSON="$OUT"
    break
  fi
done

if [[ -z "$PASS_JSON" ]]; then
  echo "e2e-matrix-mentions: FAIL — ${MAX_WAIT}s 内未找到合格团队 agent 消息（matrix.to + m.mentions 含 @dev/@qa 且无脏 ID）" >&2
  echo "e2e-matrix-mentions: 检查 LLM、openclaw 日志；MATRIX_SERVER_NAME=${MX_SRV}" >&2
  exit 4
fi

echo "e2e-matrix-mentions: PASS $PASS_JSON"
