#!/bin/bash
# Matrix 初始化：等待 HS、注册用户、建群、邀请、自动加入

wait_for_homeserver() {
  local i=1
  log_info "等待 Matrix homeserver（Tuwunel）就绪..."
  while [ "$i" -le 60 ]; do
    if curl -sf "${MATRIX_HOMESERVER_URL}/_matrix/client/versions" >/dev/null 2>&1; then
      log_info "Matrix homeserver 已就绪"
      return 0
    fi
    sleep 2
    i=$((i + 1))
  done
  log_warn "Matrix homeserver 等待超时"
  return 1
}

agent_env_password_var() {
  local a="$1"
  echo "${a}" | tr 'a-z-' 'A-Z_' | sed 's/$/_PASSWORD/'
}

ensure_passwords() {
  mkdir -p "$OPENCLAW_ROOT"
  if [ -f "$PASSWORDS_FILE" ]; then
    log_info "使用已有密码文件 $PASSWORDS_FILE"
    return 0
  fi
  : > "$PASSWORDS_FILE"
  local a var pw
  for a in $AGENTS; do
    var="$(agent_env_password_var "$a")"
    pw="${!var:-}"
    if [ -z "$pw" ]; then
      if command -v openssl >/dev/null 2>&1; then
        pw="$(openssl rand -hex 16)"
      else
        pw="$(head -c 16 /dev/urandom | xxd -p -c 32 2>/dev/null | head -1)"
      fi
      log_warn "未设置 ${var}，已为 ${a} 生成随机密码（请写入 .env 以便复现）"
    fi
    echo "${a}=${pw}" >> "$PASSWORDS_FILE"
  done
}

ensure_human_password() {
  if [ -n "${HUMAN_PASSWORD:-}" ]; then
    return 0
  fi
  if command -v openssl >/dev/null 2>&1; then
    HUMAN_PASSWORD="$(openssl rand -hex 16)"
  else
    HUMAN_PASSWORD="$(head -c 16 /dev/urandom | xxd -p -c 32 2>/dev/null | head -1)"
  fi
  export HUMAN_PASSWORD
  log_warn "HUMAN_PASSWORD 未在 .env 中设置，已生成随机密码（仅供首次登录，请记入 .env）"
}

matrix_register_or_login() {
  local user="$1" pass="$2"
  local reg tok
  reg="${MATRIX_REGISTRATION_TOKEN:-}"
  if [ -z "$reg" ]; then
    log_warn "MATRIX_REGISTRATION_TOKEN 未设置，无法注册 $user"
    return 1
  fi
  if [ ! -f "$MATRIX_ENSURE_USER_PY" ]; then
    log_warn "缺少 $MATRIX_ENSURE_USER_PY"
    return 1
  fi
  tok="$(python3 "$MATRIX_ENSURE_USER_PY" "${MATRIX_HOMESERVER_URL}" "$user" "$pass" "$reg" 2>/dev/null || true)"
  printf '%s' "$tok"
}

save_agent_token() {
  local u="$1" tok="$2"
  [ -z "$tok" ] && return 0
  touch "$TOKENS_FILE"
  local tmp="${TOKENS_FILE}.tmp.$$"
  if [ -f "$TOKENS_FILE" ]; then
    grep -v "^${u}=" "$TOKENS_FILE" >"$tmp" 2>/dev/null || : >"$tmp"
  else
    : >"$tmp"
  fi
  echo "${u}=${tok}" >>"$tmp"
  mv "$tmp" "$TOKENS_FILE"
}

bootstrap_matrix_accounts() {
  ensure_human_password
  log_info "注册/登录 Human @${HUMAN_USERNAME}:${MATRIX_SERVER_NAME}..."
  HUMAN_TOKEN="$(matrix_register_or_login "$HUMAN_USERNAME" "$HUMAN_PASSWORD" || true)"
  export HUMAN_TOKEN

  log_info "注册/登录 Agent 账号..."
  local line user pass tok any=""
  while IFS='=' read -r user pass; do
    [ -z "${user:-}" ] && continue
    tok="$(matrix_register_or_login "$user" "$pass")"
    if [ -n "$tok" ]; then
      any=1
      save_agent_token "$user" "$tok"
    else
      log_warn "无法获取 $user 的 Matrix access_token（请检查密码、MATRIX_REGISTRATION_TOKEN 与 .env）"
    fi
  done <"$PASSWORDS_FILE" || true
  if [ -z "$any" ]; then
    log_warn "未写入任何 agent token（$TOKENS_FILE）；OpenClaw 无法连接 Matrix"
  elif [ ! -s "$TOKENS_FILE" ]; then
    log_warn "$TOKENS_FILE 为空"
  else
    log_info "已刷新 Matrix tokens: $TOKENS_FILE"
  fi
}

load_or_assign_room_id() {
  if [ -n "${MATRIX_ROOM_ID:-}" ]; then
    return 0
  fi
  if [ -f "$MATRIX_ROOM_CACHE" ]; then
    MATRIX_ROOM_ID="$(tr -d '\r\n' <"$MATRIX_ROOM_CACHE")"
    export MATRIX_ROOM_ID
  fi
}

create_team_room_if_needed() {
  load_or_assign_room_id
  if [ -n "${MATRIX_ROOM_ID:-}" ]; then
    log_info "使用已有团队房间: $MATRIX_ROOM_ID"
    return 0
  fi
  local creator_tok="${HUMAN_TOKEN:-}"
  if [ -z "$creator_tok" ]; then
    log_warn "无 Human token，跳过自动建群（可稍后设置 MATRIX_ROOM_ID）"
    return 0
  fi
  local resp rid
  resp="$(curl -sf -X POST "${MATRIX_HOMESERVER_URL}/_matrix/client/v3/createRoom" \
    -H "Authorization: Bearer ${creator_tok}" \
    -H "Content-Type: application/json" \
    -d "$(
      node -e "console.log(JSON.stringify({name:process.argv[1],preset:'public_chat',initial_state:[{type:'m.room.history_visibility',content:{history_visibility:'world_readable'}}],room_version:'11'}))" \
        "$TEAM_ROOM_NAME"
    )" 2>&1)" || true
  rid="$(printf '%s' "$resp" | json_get room_id)"
  if [ -z "$rid" ]; then
    log_warn "自动创建房间失败: ${resp:0:200}"
    return 0
  fi
  printf '%s' "$rid" >"$MATRIX_ROOM_CACHE"
  MATRIX_ROOM_ID="$rid"
  export MATRIX_ROOM_ID
  log_info "已创建团队房间: $rid"
}

matrix_invite_localpart() {
  local inviter_tok="$1" room_id="$2" localpart="$3"
  local uid enc http tmp_resp
  uid="@${localpart}:${MATRIX_SERVER_NAME}"
  enc="$(node -e "console.log(encodeURIComponent(process.argv[1]))" "$room_id")"
  tmp_resp="$(mktemp)"
  http="$(curl -sS -o "$tmp_resp" -w "%{http_code}" -X POST "${MATRIX_HOMESERVER_URL}/_matrix/client/v3/rooms/${enc}/invite" \
    -H "Authorization: Bearer ${inviter_tok}" \
    -H "Content-Type: application/json" \
    -d "$(node -e "console.log(JSON.stringify({user_id:process.argv[1]}))" "$uid")")" || true
  if [ "$http" = "200" ]; then
    log_info "已邀请进房: $uid"
    rm -f "$tmp_resp"; return 0
  fi
  if grep -qiE 'already in the room|already a member|is already in the' "$tmp_resp" 2>/dev/null; then
    log_info "已在房间内（跳过）: $uid"
    rm -f "$tmp_resp"; return 0
  fi
  log_warn "邀请 $uid 失败 HTTP=${http}: $(head -c 240 "$tmp_resp" 2>/dev/null | tr -d '\r\n')"
  rm -f "$tmp_resp"; return 1
}

invite_all_team_members() {
  load_or_assign_room_id
  [ -n "${MATRIX_ROOM_ID:-}" ] || return 0
  local inviter_tok="${HUMAN_TOKEN:-}"
  if [ -z "$inviter_tok" ]; then
    log_warn "无 Human token，无法自动邀请成员进群"
    return 0
  fi
  if [ -f "$INVITES_DONE_FILE" ] && grep -qxF "$MATRIX_ROOM_ID" "$INVITES_DONE_FILE" 2>/dev/null; then
    log_info "团队房间成员已邀请过（$MATRIX_ROOM_ID），跳过"
    return 0
  fi
  log_info "邀请各 Agent 进入团队房间..."
  local a
  for a in $AGENTS; do
    matrix_invite_localpart "$inviter_tok" "$MATRIX_ROOM_ID" "$a" || true
  done
  printf '%s\n' "$MATRIX_ROOM_ID" >"$INVITES_DONE_FILE"
  log_info "团队房间邀请完成"
}

matrix_join_team_room_as() {
  local tok="$1" room_id="$2" who="$3"
  local enc http tmp_resp
  [ -n "$tok" ] || return 0
  enc="$(node -e "console.log(encodeURIComponent(process.argv[1]))" "$room_id")"
  tmp_resp="$(mktemp)"
  http="$(curl -sS -o "$tmp_resp" -w "%{http_code}" -X POST "${MATRIX_HOMESERVER_URL}/_matrix/client/v3/rooms/${enc}/join" \
    -H "Authorization: Bearer ${tok}" \
    -H "Content-Type: application/json" \
    -d '{}' 2>/dev/null)" || true
  if [ "$http" = "200" ]; then
    log_info "已自动加入团队房间: $who"
    rm -f "$tmp_resp"; return 0
  fi
  if grep -qiE 'already in the room|already a member|already joined' "$tmp_resp" 2>/dev/null; then
    log_info "已在团队房间内: $who"
    rm -f "$tmp_resp"; return 0
  fi
  log_warn "自动加入房间失败 ($who) HTTP=${http}: $(head -c 240 "$tmp_resp" 2>/dev/null | tr -d '\r\n')"
  rm -f "$tmp_resp"; return 1
}

auto_accept_team_room_invites() {
  load_or_assign_room_id
  [ -n "${MATRIX_ROOM_ID:-}" ] || return 0
  log_info "自动接受团队房间邀请..."
  local htok u t
  htok="$(matrix_register_or_login "$HUMAN_USERNAME" "$HUMAN_PASSWORD" 2>/dev/null || true)"
  if [ -z "$htok" ]; then
    log_warn "Human 登录失败，无法自动 join"
  else
    matrix_join_team_room_as "$htok" "$MATRIX_ROOM_ID" "@${HUMAN_USERNAME}:${MATRIX_SERVER_NAME}" || true
  fi
  [ -f "$TOKENS_FILE" ] || return 0
  while IFS='=' read -r u t; do
    [ -z "${u:-}" ] && continue
    [ -z "${t:-}" ] && continue
    matrix_join_team_room_as "$t" "$MATRIX_ROOM_ID" "@${u}:${MATRIX_SERVER_NAME}" || true
  done <"$TOKENS_FILE" || true
}
