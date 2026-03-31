#!/bin/bash
# 以 manager 身份创建「团队房间」、邀请 Human 与全部 Agent，并写入 volumes/openclaw/.matrix-team-room-id。
# 依赖：已 make up；建议先 bash matrix/sync-all-matrix-passwords.sh；需本机 python3。
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

SYNAPSE_SERVER_NAME="$(get_env_val SYNAPSE_SERVER_NAME)"; SYNAPSE_SERVER_NAME="${SYNAPSE_SERVER_NAME:-localhost}"
SYNAPSE_PORT="$(get_env_val SYNAPSE_PORT)"; SYNAPSE_PORT="${SYNAPSE_PORT:-8008}"
HS="http://127.0.0.1:${SYNAPSE_PORT}"
MANAGER_PW="$(get_env_val MANAGER_PASSWORD)"
TEAM_NAME="$(get_env_val TEAM_ROOM_NAME)"; TEAM_NAME="${TEAM_NAME:-Claw Team}"
HUMAN_USERNAME="$(get_env_val HUMAN_USERNAME)"; HUMAN_USERNAME="${HUMAN_USERNAME:-human}"
OPENCLAW_VOL="$ROOT/volumes/openclaw"
ROOM_FILE="$OPENCLAW_VOL/.matrix-team-room-id"
INVITES_DONE="$OPENCLAW_VOL/.team-room-invites-done"

[ -n "$MANAGER_PW" ] || { echo "缺少 MANAGER_PASSWORD"; exit 1; }
[ -d "$OPENCLAW_VOL" ] || mkdir -p "$OPENCLAW_VOL"

export HS SYNAPSE_SERVER_NAME MANAGER_PW TEAM_NAME HUMAN_USERNAME ROOM_FILE INVITES_DONE
export HUMAN_PASSWORD="$(get_env_val HUMAN_PASSWORD)"
export ARCH_PASSWORD="$(get_env_val ARCH_PASSWORD)"
export DEV_PASSWORD="$(get_env_val DEV_PASSWORD)"
export QA_PASSWORD="$(get_env_val QA_PASSWORD)"
export SRE_PASSWORD="$(get_env_val SRE_PASSWORD)"
export RESEARCH_PASSWORD="$(get_env_val RESEARCH_PASSWORD)"

python3 <<'PY'
import json, os, urllib.error, urllib.parse, urllib.request

hs = os.environ["HS"]
srv = os.environ["SYNAPSE_SERVER_NAME"]
mpw = os.environ["MANAGER_PW"]
team = os.environ["TEAM_NAME"]
human = os.environ["HUMAN_USERNAME"]
room_file = os.environ["ROOM_FILE"]
invites_done = os.environ["INVITES_DONE"]
agents = ["arch", "dev", "manager", "qa", "sre", "research"]

def post(url, data=None, headers=None, method="POST"):
    h = {"Content-Type": "application/json"}
    if headers:
        h.update(headers)
    req = urllib.request.Request(url, data=(json.dumps(data).encode() if data is not None else None), headers=h, method=method)
    return urllib.request.urlopen(req, timeout=60)

def login(local, password):
    r = post(
        f"{hs}/_matrix/client/v3/login",
        {"type": "m.login.password", "identifier": {"type": "m.id.user", "user": local}, "password": password},
    )
    return json.load(r)["access_token"]

mtok = login("manager", mpw)
room_id = None
if os.path.isfile(room_file):
    rid = open(room_file).read().strip()
    if rid.startswith("!"):
        room_id = rid

if not room_id:
    body = {
        "name": team,
        "preset": "public_chat",
        "initial_state": [{"type": "m.room.history_visibility", "content": {"history_visibility": "world_readable"}}],
        "room_version": "11",
    }
    r = post(f"{hs}/_matrix/client/v3/createRoom", body, {"Authorization": f"Bearer {mtok}"})
    room_id = json.load(r)["room_id"]
    open(room_file, "w").write(room_id + "\n")
    print("已创建房间:", room_id)
else:
    print("使用已有房间:", room_id)

enc = urllib.parse.quote(room_id, safe="")
for lp in [human] + agents:
    uid = f"@{lp}:{srv}"
    req = urllib.request.Request(
        f"{hs}/_matrix/client/v3/rooms/{enc}/invite",
        data=json.dumps({"user_id": uid}).encode(),
        headers={"Authorization": f"Bearer {mtok}", "Content-Type": "application/json"},
        method="POST",
    )
    try:
        urllib.request.urlopen(req, timeout=30)
        print("已邀请", uid)
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        if e.code == 403 and ("already in the room" in body.lower() or "already a member" in body.lower()):
            print("已在房内", uid)
        else:
            print("邀请失败", uid, e.code, body[:300])


def join_as(localpart, password):
    if not password:
        print("跳过自动加入（无密码）:", localpart)
        return
    try:
        tok = login(localpart, password)
    except Exception as ex:
        print("登录失败，无法 join:", localpart, ex)
        return
    enc = urllib.parse.quote(room_id, safe="")
    req = urllib.request.Request(
        f"{hs}/_matrix/client/v3/rooms/{enc}/join",
        data=b"{}",
        headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"},
        method="POST",
    )
    try:
        urllib.request.urlopen(req, timeout=30)
        print("已自动加入房间:", localpart)
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace").lower()
        if e.code == 200:
            return
        if "already" in body and ("room" in body or "member" in body):
            print("已在房间内:", localpart)
        else:
            print("join 失败:", localpart, e.code, body[:200])


print("\n自动接受邀请（join）…")
join_as(human, os.environ.get("HUMAN_PASSWORD"))
for lp, envk in [
    ("arch", "ARCH_PASSWORD"),
    ("dev", "DEV_PASSWORD"),
    ("manager", "MANAGER_PW"),
    ("qa", "QA_PASSWORD"),
    ("sre", "SRE_PASSWORD"),
    ("research", "RESEARCH_PASSWORD"),
]:
    join_as(lp, os.environ.get(envk))

open(invites_done, "w").write(room_id + "\n")
print("\n房间 ID 已写入", room_file)
print("请重启 openclaw 容器以让 Gateway 读取房间 ID： docker compose -f deploy/docker-compose.yml --env-file .env restart openclaw")
PY
