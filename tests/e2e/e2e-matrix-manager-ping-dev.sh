#!/usr/bin/env bash
# E2E：以 **sre** Matrix 账号在团队房 @dev（agent→agent）。曾用 manager 发起时 dev 常拒绝在正文写 @manager；sre 无「角色冲突」提示，更适合自动化。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/.env"

MX_SRV="${MATRIX_SERVER_NAME:-localhost}"
export E2E_MX_SRV="$MX_SRV"
PEER_FULL="@sre:${MX_SRV}"
E2E_TAG="e2e-peer-dev"
export E2E_PING_BODY="@dev:${MX_SRV} [${E2E_TAG}] 请只回复一条消息，正文必须包含完整 Matrix ID ${PEER_FULL}（不要用短 @sre）。"

TOKENS_FILE="${ROOT}/volumes/openclaw/.agent-tokens"
[[ -f "$TOKENS_FILE" ]] || {
  echo "e2e-matrix-peer-dev: 缺少 $TOKENS_FILE" >&2
  exit 2
}

export E2E_TOKENS_FILE="$TOKENS_FILE"
PEER_TOK="$(python3 <<'PY'
import os
for line in open(os.environ["E2E_TOKENS_FILE"]):
    line = line.strip()
    if line.startswith("sre="):
        print(line[4:], end="")
        break
PY
)"
[[ -n "$PEER_TOK" ]] || {
  echo "e2e-matrix-peer-dev: .agent-tokens 中无 sre=" >&2
  exit 2
}

export E2E_MATRIX_USER="${HUMAN_USERNAME:-human}"
export E2E_MATRIX_PASS="${HUMAN_PASSWORD:?HUMAN_PASSWORD missing}"

HUMAN_TOK_PAYLOAD="$(python3 <<'PY'
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

SYNAPSE="${MATRIX_URL:-http://127.0.0.1:${MATRIX_PORT:-8008}}"
ROOM_FILE="${ROOT}/volumes/openclaw/.matrix-team-room-id"
ROOM_RAW="$(tr -d '[:space:]' <"$ROOM_FILE")"
ROOM_ENC="$(python3 -c "import urllib.parse; print(urllib.parse.quote('$ROOM_RAW', safe=''))")"

LOGIN="$(curl -sf -X POST "${SYNAPSE}/_matrix/client/v3/login" \
  -H 'Content-Type: application/json' \
  -d "$HUMAN_TOK_PAYLOAD")" || exit 2
export E2E_LOGIN_JSON="$LOGIN"
HUMAN_ACCESS="$(python3 -c "import json,os; print(json.loads(os.environ['E2E_LOGIN_JSON'])['access_token'])")"

TXN="e2e-peer-dev-$(date +%s)"
export E2E_DEV_MXID="@dev:${MX_SRV}"
export E2E_PEER_MXID="${PEER_FULL}"
PING_PAYLOAD="$(python3 <<'PY'
import json, os, urllib.parse

def mto(mxid: str) -> str:
    return "https://matrix.to/#/" + urllib.parse.quote(mxid, safe='')

body = os.environ["E2E_PING_BODY"]
dev = os.environ["E2E_DEV_MXID"]
peer = os.environ["E2E_PEER_MXID"]
tag = "e2e-peer-dev"
html = (
    f'<p><a href="{mto(dev)}">{dev}</a> [{tag}] 请只回复一条消息，正文必须包含完整 Matrix ID '
    f'<a href="{mto(peer)}">{peer}</a>（不要用短 @sre）。</p>'
)
print(
    json.dumps(
        {
            "msgtype": "m.text",
            "body": body,
            "format": "org.matrix.custom.html",
            "formatted_body": html,
            "m.mentions": {"user_ids": [dev]},
        }
    )
)
PY
)"

SEND="$(curl -sf -X PUT "${SYNAPSE}/_matrix/client/v3/rooms/${ROOM_ENC}/send/m.room.message/${TXN}" \
  -H "Authorization: Bearer ${PEER_TOK}" \
  -H 'Content-Type: application/json' \
  -d "$PING_PAYLOAD")" || {
  echo "e2e-matrix-peer-dev: sre 发消息失败" >&2
  exit 3
}

export E2E_SEND_JSON="$SEND"
TRIG="$(python3 -c "import json,os; print(json.loads(os.environ['E2E_SEND_JSON'])['event_id'])")"
export E2E_TRIG_ID="$TRIG"
TRIG_ENC="$(python3 -c "import urllib.parse, os; print(urllib.parse.quote(os.environ['E2E_TRIG_ID'], safe=''))")"
TRIG_TS="$(curl -sf "${SYNAPSE}/_matrix/client/v3/rooms/${ROOM_ENC}/event/${TRIG_ENC}" \
  -H "Authorization: Bearer ${HUMAN_ACCESS}" | python3 -c "import json,sys; print(json.load(sys.stdin)['origin_server_ts'])")" || exit 3

printf 'e2e-matrix-peer-dev: trigger %s (server=%s, sender=sre)\n' "$TRIG" "$MX_SRV"

export E2E_TRIG_TS="$TRIG_TS"
export E2E_TOKEN="$HUMAN_ACCESS"
export E2E_ROOM_ENC="$ROOM_ENC"
export E2E_SYNAPSE="$SYNAPSE"
export E2E_PEER_FULL="$PEER_FULL"

MAX_WAIT=300
STEP=5
elapsed=0
PASS_JSON=""
try_pass() {
  local RAW="$1"
  printf '%s' "$RAW" | python3 -c "
import json, os, sys, urllib.parse
raw = json.load(sys.stdin)
cut = int(os.environ['E2E_TRIG_TS'])
srv = os.environ['E2E_MX_SRV']
peer_full = os.environ['E2E_PEER_FULL']
sre_sender = '@sre:' + srv
roles = ('arch', 'dev', 'manager', 'qa', 'sre', 'research')
allowed = {'@' + r + ':' + srv for r in roles}
BAD = {'@q:' + srv, '@de:' + srv, '@arc:' + srv}
for ev in raw.get('chunk') or []:
    if ev.get('type') != 'm.room.message':
        continue
    sender = ev.get('sender') or ''
    if sender not in allowed:
        continue
    if sender == sre_sender:
        continue
    ts = ev.get('origin_server_ts') or 0
    if ts <= cut:
        continue
    c = ev.get('content') or {}
    body = (c.get('body') or '').lower()
    if 'e2e-peer-dev' in body:
        continue
    body_raw = c.get('body') or ''
    mm = c.get('m.mentions') or {}
    u = mm.get('user_ids') or []
    if any(x in BAD for x in u):
        sys.exit(1)
    fb = c.get('formatted_body') or ''
    peer_enc = urllib.parse.quote(peer_full, safe='')
    peer_in_fb = peer_full in fb or peer_enc in fb
    if peer_full not in body_raw and '@sre' not in body_raw and not peer_in_fb:
        continue
    if not u or peer_full not in u:
        continue
    if 'matrix.to/#/' not in fb:
        continue
    print(json.dumps({'ok': True, 'event_id': ev.get('event_id'), 'sender': sender, 'mentions': u, 'body_head': body_raw[:120]}))
    sys.exit(0)
sys.exit(1)
"
}

while [[ "$elapsed" -lt "$MAX_WAIT" ]]; do
  sleep "$STEP"
  elapsed=$((elapsed + STEP))
  RAW="$(curl -sf "${E2E_SYNAPSE}/_matrix/client/v3/rooms/${E2E_ROOM_ENC}/messages?dir=b&limit=120" \
    -H "Authorization: Bearer ${E2E_TOKEN}")" || continue
  [[ -n "$RAW" ]] || continue
  if OUT="$(try_pass "$RAW")"; then
    PASS_JSON="$OUT"
    break
  fi
  if [[ "$elapsed" -eq 90 && -z "${E2E_PEER_DEV_RETRIED:-}" ]]; then
    export E2E_PEER_DEV_RETRIED=1
    TXN2="e2e-peer-dev-retry-$(date +%s)"
    curl -sf -X PUT "${E2E_SYNAPSE}/_matrix/client/v3/rooms/${E2E_ROOM_ENC}/send/m.room.message/${TXN2}" \
      -H "Authorization: Bearer ${PEER_TOK}" \
      -H 'Content-Type: application/json' \
      -d "$PING_PAYLOAD" >/dev/null || true
    echo "e2e-matrix-peer-dev: retry ping sent" >&2
  fi
done

if [[ -z "$PASS_JSON" ]]; then
  echo "e2e-matrix-peer-dev: FAIL — ${MAX_WAIT}s 内无合格回复（须 @sre + m.mentions + matrix.to，且非 sre 自发自收）" >&2
  exit 4
fi

echo "e2e-matrix-peer-dev: PASS $PASS_JSON"
