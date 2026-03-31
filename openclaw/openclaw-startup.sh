#!/bin/bash
# OpenClaw 容器入口：等待 Matrix HS（Tuwunel）→ 注册/登录 → Gateway → Matrix channel → workspaces
set -euo pipefail

OPENCLAW_ROOT="${OPENCLAW_ROOT:-/root/.openclaw}"
OPENCLAW_SOURCE="${OPENCLAW_SOURCE:-/app/.openclaw}"
SYNAPSE_ENDPOINT="${SYNAPSE_ENDPOINT:-http://tuwunel:8008}"
MATRIX_ENSURE_USER_PY="${MATRIX_ENSURE_USER_PY:-/app/platform/matrix-ensure-user.py}"

# 环境变量由 docker compose env_file 注入；勿 source /app/.env（未加引号的空格会破坏 bash）

SYNAPSE_SERVER_NAME="${SYNAPSE_SERVER_NAME:-localhost}"
HUMAN_USERNAME="${HUMAN_USERNAME:-human}"
AGENTS="arch dev manager qa sre research"
PASSWORDS_FILE="$OPENCLAW_ROOT/.agent-passwords"
TOKENS_FILE="$OPENCLAW_ROOT/.agent-tokens"
OPENCLAW_JSON="$OPENCLAW_ROOT/openclaw.json"
MATRIX_ROOM_CACHE="$OPENCLAW_ROOT/.matrix-team-room-id"
# 团队房显示名：优先 PROJECT_NAME（按项目命名），否则 TEAM_ROOM_NAME，默认 Claw Team
TEAM_ROOM_NAME="${PROJECT_NAME:-${TEAM_ROOM_NAME:-Claw Team}}"

log_info() { echo "[openclaw-startup] $*"; }
log_warn() { echo "[openclaw-startup] WARNING: $*" >&2; }

wait_for_synapse() {
  local i=1
  log_info "等待 Matrix homeserver（Tuwunel）就绪..."
  while [ "$i" -le 60 ]; do
    if curl -sf "${SYNAPSE_ENDPOINT}/_matrix/client/versions" >/dev/null 2>&1; then
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
  case "$a" in
    arch) echo "ARCH_PASSWORD" ;;
    dev) echo "DEV_PASSWORD" ;;
    manager) echo "MANAGER_PASSWORD" ;;
    qa) echo "QA_PASSWORD" ;;
    sre) echo "SRE_PASSWORD" ;;
    research) echo "RESEARCH_PASSWORD" ;;
    *) echo "" ;;
  esac
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

json_get() {
  local key="$1"
  node -e "try{const d=JSON.parse(require('fs').readFileSync(0,'utf8')); console.log(d['${key}']||'');}catch(e){console.log('');}"
}

# 返回 access_token 到 stdout；失败为空（Tuwunel：标准注册 + registration_token，无 Synapse Admin API）
synapse_register_or_login() {
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
  tok="$(python3 "$MATRIX_ENSURE_USER_PY" "${SYNAPSE_ENDPOINT}" "$user" "$pass" "$reg" 2>/dev/null || true)"
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
  log_info "注册/登录 Human @${HUMAN_USERNAME}:${SYNAPSE_SERVER_NAME}..."
  synapse_register_or_login "$HUMAN_USERNAME" "$HUMAN_PASSWORD" >/dev/null || true

  log_info "注册/登录 Agent 账号..."
  local line user pass tok any=""
  # read 遇 EOF 返回 1，整个 while 复合命令会以 1 结束；set -e 会因此退出脚本
  while IFS='=' read -r user pass; do
    [ -z "${user:-}" ] && continue
    tok="$(synapse_register_or_login "$user" "$pass")"
    if [ -n "$tok" ]; then
      any=1
      save_agent_token "$user" "$tok"
    else
      log_warn "无法获取 $user 的 Matrix access_token（请检查密码、MATRIX_REGISTRATION_TOKEN 与 .env / $PASSWORDS_FILE；已存在用户改密需 make fresh 或客户端修改）"
    fi
  done <"$PASSWORDS_FILE" || true
  if [ -z "$any" ]; then
    log_warn "未写入任何 agent token（$TOKENS_FILE）；OpenClaw 无法连接 Matrix，群里 @agent 不会回复"
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
  local mgr_tok
  mgr_tok="$(awk -F= '$1=="manager" {print $2; exit}' "$TOKENS_FILE" 2>/dev/null || true)"
  if [ -z "$mgr_tok" ]; then
    log_warn "无 manager token，跳过自动建群（可稍后设置 MATRIX_ROOM_ID）"
    return 0
  fi
  local resp rid enc
  resp="$(curl -sf -X POST "${SYNAPSE_ENDPOINT}/_matrix/client/v3/createRoom" \
    -H "Authorization: Bearer ${mgr_tok}" \
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

# 使用 manager 的 token 将 human + 全部 agent 拉入团队房间（幂等：同房间仅完整执行一次）
INVITES_DONE_FILE="$OPENCLAW_ROOT/.team-room-invites-done"

matrix_invite_localpart() {
  local inviter_tok="$1"
  local room_id="$2"
  local localpart="$3"
  local uid enc http tmp_resp
  uid="@${localpart}:${SYNAPSE_SERVER_NAME}"
  enc="$(node -e "console.log(encodeURIComponent(process.argv[1]))" "$room_id")"
  tmp_resp="$(mktemp)"
  http="$(curl -sS -o "$tmp_resp" -w "%{http_code}" -X POST "${SYNAPSE_ENDPOINT}/_matrix/client/v3/rooms/${enc}/invite" \
    -H "Authorization: Bearer ${inviter_tok}" \
    -H "Content-Type: application/json" \
    -d "$(node -e "console.log(JSON.stringify({user_id:process.argv[1]}))" "$uid")")" || true
  if [ "$http" = "200" ]; then
    log_info "已邀请进房: $uid"
    rm -f "$tmp_resp"
    return 0
  fi
  if grep -qiE 'already in the room|already a member|is already in the' "$tmp_resp" 2>/dev/null; then
    log_info "已在房间内（跳过）: $uid"
    rm -f "$tmp_resp"
    return 0
  fi
  log_warn "邀请 $uid 失败 HTTP=${http}: $(head -c 240 "$tmp_resp" 2>/dev/null | tr -d '\r\n')"
  rm -f "$tmp_resp"
  return 1
}

invite_all_team_members() {
  load_or_assign_room_id
  [ -n "${MATRIX_ROOM_ID:-}" ] || return 0
  local mgr_tok
  mgr_tok="$(awk -F= '$1=="manager" {print $2; exit}' "$TOKENS_FILE" 2>/dev/null || true)"
  if [ -z "$mgr_tok" ]; then
    log_warn "无 manager token，无法自动邀请成员进群"
    return 0
  fi
  if [ -f "$INVITES_DONE_FILE" ] && grep -qxF "$MATRIX_ROOM_ID" "$INVITES_DONE_FILE" 2>/dev/null; then
    log_info "团队房间成员已邀请过（$MATRIX_ROOM_ID），跳过"
    return 0
  fi

  log_info "邀请 Human 与各 Agent 进入团队房间..."
  matrix_invite_localpart "$mgr_tok" "$MATRIX_ROOM_ID" "$HUMAN_USERNAME" || true
  local a
  for a in $AGENTS; do
    matrix_invite_localpart "$mgr_tok" "$MATRIX_ROOM_ID" "$a" || true
  done

  printf '%s\n' "$MATRIX_ROOM_ID" >"$INVITES_DONE_FILE"
  log_info "团队房间邀请流程结束（若需对新房重做邀请，删除 $INVITES_DONE_FILE 后重启容器）"
}

# POST /rooms/{roomId}/join — 等同客户端 Accept 邀请（幂等）
matrix_join_team_room_as() {
  local tok="$1" room_id="$2" who="$3"
  local enc http tmp_resp
  [ -n "$tok" ] || return 0
  enc="$(node -e "console.log(encodeURIComponent(process.argv[1]))" "$room_id")"
  tmp_resp="$(mktemp)"
  http="$(curl -sS -o "$tmp_resp" -w "%{http_code}" -X POST "${SYNAPSE_ENDPOINT}/_matrix/client/v3/rooms/${enc}/join" \
    -H "Authorization: Bearer ${tok}" \
    -H "Content-Type: application/json" \
    -d '{}' 2>/dev/null)" || true
  if [ "$http" = "200" ]; then
    log_info "已自动加入团队房间: $who"
    rm -f "$tmp_resp"
    return 0
  fi
  if grep -qiE 'already in the room|already a member|already joined' "$tmp_resp" 2>/dev/null; then
    log_info "已在团队房间内: $who"
    rm -f "$tmp_resp"
    return 0
  fi
  log_warn "自动加入房间失败 ($who) HTTP=${http}: $(head -c 240 "$tmp_resp" 2>/dev/null | tr -d '\r\n')"
  rm -f "$tmp_resp"
  return 1
}

auto_accept_team_room_invites() {
  load_or_assign_room_id
  [ -n "${MATRIX_ROOM_ID:-}" ] || return 0
  log_info "自动接受团队房间（Matrix join，等同 Element 点接受）..."
  local htok line u t
  htok="$(synapse_register_or_login "$HUMAN_USERNAME" "$HUMAN_PASSWORD" 2>/dev/null || true)"
  if [ -z "$htok" ]; then
    log_warn "Human 登录失败，无法自动 join（请检查 HUMAN_PASSWORD 与 homeserver 是否一致）"
  else
    matrix_join_team_room_as "$htok" "$MATRIX_ROOM_ID" "@${HUMAN_USERNAME}:${SYNAPSE_SERVER_NAME}" || true
  fi
  [ -f "$TOKENS_FILE" ] || return 0
  while IFS='=' read -r u t; do
    [ -z "${u:-}" ] && continue
    [ -z "${t:-}" ] && continue
    matrix_join_team_room_as "$t" "$MATRIX_ROOM_ID" "@${u}:${SYNAPSE_SERVER_NAME}" || true
  done <"$TOKENS_FILE" || true
}

start_gateway() {
  if openclaw health >/dev/null 2>&1; then
    log_info "Gateway 已在运行"
    return 0
  fi
  log_info "启动 OpenClaw Gateway..."
  nohup openclaw gateway run --port "${OPENCLAW_PORT:-18789}" --allow-unconfigured >/tmp/gateway.log 2>&1 &
  local i=1
  while [ "$i" -le 45 ]; do
    if openclaw health >/dev/null 2>&1; then
      log_info "Gateway 就绪"
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done
  log_warn "Gateway 启动超时，请检查 /tmp/gateway.log"
  return 1
}

generate_openclaw_json() {
  mkdir -p "$OPENCLAW_ROOT"
  load_or_assign_room_id
  local room_id="${MATRIX_ROOM_ID:-}"

  if [ -f "$OPENCLAW_JSON" ]; then
    log_info "保留已有 openclaw.json，仅尝试补充 Matrix routing"
  else
    log_info "生成 openclaw.json..."
    export OC_ROOM_ID="$room_id"
    export OC_SYNAPSE="$SYNAPSE_ENDPOINT"
    export OC_SYNAPSE_SERVER_NAME="$SYNAPSE_SERVER_NAME"
    export OC_OUT="$OPENCLAW_JSON"
    node <<'NODE'
const fs = require('fs');
const roomId = process.env.OC_ROOM_ID || '';
const synapse = process.env.OC_SYNAPSE;
const server = process.env.OC_SYNAPSE_SERVER_NAME || 'localhost';
const out = process.env.OC_OUT;
const ROLES = ['arch', 'dev', 'manager', 'qa', 'sre', 'research'];
const apiKey = process.env.ANTHROPIC_API_KEY || '';
const model = process.env.MODEL_NAME || 'claude-sonnet-4-20250514';
const baseUrl = (process.env.ANTHROPIC_BASE_URL || '').trim();
// OpenClaw 内置目录只有 anthropic/claude-*；自建/ MiniMax 等 Anthropic 兼容网关上的
// 模型名（如 minimax-m25、MiniMax-M2.1）须用 minimax 提供方并注册 models.providers（见 OpenClaw 文档 providers/minimax）。
const useMinimaxProvider = Boolean(baseUrl) && !/^claude-/i.test(model);
const mentionFor = (id) => {
  const cap = id.charAt(0).toUpperCase() + id.slice(1);
  return [
    `@${id}`,
    `@${cap}`,
    `@${id}:${server}`,
    `@${cap}:${server}`,
    `matrix.to/#/@${id}:${server}`,
  ];
};
const agents = [{ id: 'main', default: true, workspace: '/root/.openclaw/workspace' }];
for (const id of ROLES) {
  agents.push({
    id,
    workspace: `/root/.openclaw/workspace-${id}`,
    groupChat: { mentionPatterns: mentionFor(id) }
  });
}
const envBlock = { ANTHROPIC_API_KEY: apiKey };
if (baseUrl) envBlock.ANTHROPIC_BASE_URL = baseUrl;
if (useMinimaxProvider) envBlock.MINIMAX_API_KEY = apiKey;
const minimaxModelsCfg = {
  mode: 'merge',
  providers: {
    minimax: {
      baseUrl: baseUrl.replace(/\/$/, ''),
      api: 'anthropic-messages',
      apiKey,
      models: [
        {
          id: model,
          name: model,
          reasoning: true,
          input: ['text'],
          contextWindow: 200000,
          maxTokens: 8192,
        },
      ],
    },
  },
};
const config = {
  env: envBlock,
  messages: { ackReactionScope: 'group-mentions' },
  agents: {
    defaults: {
      model: { primary: (useMinimaxProvider ? 'minimax/' : 'anthropic/') + model },
    },
    list: agents,
  },
  ...(useMinimaxProvider ? { models: minimaxModelsCfg } : {}),
  channels: {
    matrix: {
      enabled: true,
      homeserver: synapse,
      allowPrivateNetwork: true,
      // 同 Gateway 多 Matrix 账号：仅在被 @ 时接纳其它 bot；团队房须提及才触发（见 https://docs.openclaw.ai/channels/matrix#bot-to-bot-rooms）
      allowBots: 'mentions',
      groupPolicy: 'allowlist',
      groups: {}
    }
  }
};
if (roomId) {
  config.channels.matrix.groups[roomId] = { requireMention: true, allowBots: 'mentions' };
  config.bindings = ROLES.map((agentId) => ({
    agentId,
    match: {
      channel: 'matrix',
      accountId: agentId,
      peer: { kind: 'group', id: roomId }
    }
  }));
}
fs.writeFileSync(out, JSON.stringify(config, null, 2));
NODE
  fi

  patch_openclaw_llm_from_env
  patch_bindings_if_room
}

# 每次启动根据容器环境变量刷新 openclaw.json 中的 LLM 配置（不依赖是否已有团队房 ID）
patch_openclaw_llm_from_env() {
  [ -f "$OPENCLAW_JSON" ] || return 0
  node -e "
const fs = require('fs');
const f = process.argv[1];
let c = JSON.parse(fs.readFileSync(f, 'utf8'));
const apiKey = process.env.ANTHROPIC_API_KEY || '';
const model = process.env.MODEL_NAME || 'claude-sonnet-4-20250514';
const baseUrl = (process.env.ANTHROPIC_BASE_URL || '').trim();
const useMinimaxProvider = Boolean(baseUrl) && !/^claude-/i.test(model);
c.env = c.env || {};
c.env.ANTHROPIC_API_KEY = apiKey;
if (baseUrl) c.env.ANTHROPIC_BASE_URL = baseUrl;
else delete c.env.ANTHROPIC_BASE_URL;
if (useMinimaxProvider) c.env.MINIMAX_API_KEY = apiKey;
else delete c.env.MINIMAX_API_KEY;
if (!c.agents) c.agents = {};
if (!c.agents.defaults) c.agents.defaults = {};
if (!c.agents.defaults.model) c.agents.defaults.model = {};
c.agents.defaults.model.primary = (useMinimaxProvider ? 'minimax/' : 'anthropic/') + model;
if (useMinimaxProvider) {
  c.models = c.models || {};
  c.models.mode = 'merge';
  c.models.providers = c.models.providers || {};
  c.models.providers.minimax = {
    baseUrl: baseUrl.replace(/\/$/, ''),
    api: 'anthropic-messages',
    apiKey,
    models: [
      {
        id: model,
        name: model,
        reasoning: true,
        input: ['text'],
        contextWindow: 200000,
        maxTokens: 8192,
      },
    ],
  };
} else if (c.models && c.models.providers) {
  delete c.models.providers.minimax;
  if (Object.keys(c.models.providers).length === 0) delete c.models.providers;
  if (!c.models.providers || Object.keys(c.models.providers).length === 0) {
    if (c.models && Object.keys(c.models).length === 1 && c.models.mode === 'merge') delete c.models;
  }
}
fs.writeFileSync(f, JSON.stringify(c, null, 2));
" "$OPENCLAW_JSON"
}

patch_bindings_if_room() {
  load_or_assign_room_id
  [ -f "$OPENCLAW_JSON" ] || return 0
  local room="${MATRIX_ROOM_ID:-}"
  if [ -n "$room" ]; then
    log_info "同步团队房间与 Matrix 多账号 bindings（每角色一 channel → 同群）..."
  else
    log_info "无 MATRIX_ROOM_ID：仅补充 channels.matrix.allowBots / homeserver（见 .matrix-team-room-id）"
  fi
  node -e "
const fs = require('fs');
const ROLES = ['arch','dev','manager','qa','sre','research'];
const f = process.argv[1];
const roomId = process.argv[2] || '';
const synapse = process.argv[3];
const server = process.argv[4];
const mentionFor = (id) => {
  const cap = id.charAt(0).toUpperCase() + id.slice(1);
  return ['@' + id, '@' + cap, '@' + id + ':' + server, '@' + cap + ':' + server, 'matrix.to/#/@' + id + ':' + server];
};
let c = JSON.parse(fs.readFileSync(f, 'utf8'));
if (!c.channels) c.channels = {};
if (!c.channels.matrix) c.channels.matrix = { enabled: true, homeserver: synapse, allowPrivateNetwork: true, groupPolicy: 'allowlist', groups: {} };
c.channels.matrix.homeserver = synapse;
c.channels.matrix.allowBots = 'mentions';
c.channels.matrix.groupPolicy = 'allowlist';
c.messages = c.messages || {};
c.messages.ackReactionScope = 'group-mentions';
const teamRoomCfg = { requireMention: true, allowBots: 'mentions' };
if (roomId) {
  if (!c.channels.matrix.groups) c.channels.matrix.groups = {};
  c.channels.matrix.groups[roomId] = { ...(c.channels.matrix.groups[roomId] || {}), ...teamRoomCfg };
  const ax = c.channels.matrix.accounts;
  if (ax && typeof ax === 'object') {
    for (const accId of Object.keys(ax)) {
      const acc = ax[accId];
      if (!acc || typeof acc !== 'object') continue;
      acc.groupPolicy = 'allowlist';
      acc.groups = acc.groups || {};
      acc.groups[roomId] = { ...(acc.groups[roomId] || {}), ...teamRoomCfg };
    }
  }
  c.bindings = ROLES.map((agentId) => ({
    agentId,
    match: { channel: 'matrix', accountId: agentId, peer: { kind: 'group', id: roomId } }
  }));
  let list = (c.agents && c.agents.list) || [];
  if (!Array.isArray(list)) list = [];
  for (const id of ROLES) {
    let a = list.find((x) => x.id === id);
    if (!a) { a = { id, workspace: '/root/.openclaw/workspace-' + id }; list.push(a); }
    a.groupChat = { mentionPatterns: mentionFor(id) };
  }
  const main = list.find((a) => a.id === 'main');
  if (main && main.groupChat) delete main.groupChat;
  c.agents = c.agents || {};
  c.agents.list = list;
}
fs.writeFileSync(f, JSON.stringify(c, null, 2));
" "$OPENCLAW_JSON" "$room" "$SYNAPSE_ENDPOINT" "$SYNAPSE_SERVER_NAME"
}

warn_llm_api_key() {
  local k="${ANTHROPIC_API_KEY:-}"
  if [ -z "$k" ]; then
    log_warn "ANTHROPIC_API_KEY 未设置：群里 @agent 时 LLM 会报 401，请在 .env 填写"
    return 0
  fi
  case "$k" in
    *xxxxx*|*YOUR_*|*your-key*|*placeholder*|*changeme*)
      log_warn "ANTHROPIC_API_KEY 疑似占位符：请将 .env 换成真实 Key 并 restart openclaw"
      ;;
  esac
  if [ "${#k}" -lt 24 ]; then
    log_warn "ANTHROPIC_API_KEY 长度过短，若仍报 invalid x-api-key 请检查 Key 与 MODEL_NAME 是否匹配你的供应商"
  fi
}

configure_matrix_channels() {
  [ -f "$TOKENS_FILE" ] || return 0
  log_info "配置 Matrix channels（OpenClaw）..."
  local user token
  while IFS='=' read -r user token; do
    [ -z "${user:-}" ] && continue
    if openclaw channels list 2>/dev/null | grep -qF "$user"; then
      log_info "Channel 已存在: $user"
      continue
    fi
    if openclaw channels add --channel matrix \
      --account "$user" \
      --homeserver "$SYNAPSE_ENDPOINT" \
      --access-token "$token"; then
      log_info "Matrix channel: $user"
    else
      log_warn "Matrix channel 添加失败: $user"
    fi
  done <"$TOKENS_FILE" || true
}

deploy_workspaces() {
  log_info "部署 workspace 模板..."
  local entry agent_name workspace_name source_dir target_dir
  local spec="arch:workspace-arch dev:workspace-dev manager:workspace-manager qa:workspace-qa sre:workspace-sre research:workspace-research main:workspace"
  for entry in $spec; do
    agent_name="${entry%%:*}"
    workspace_name="${entry##*:}"
    source_dir="$OPENCLAW_SOURCE/$workspace_name"
    target_dir="$OPENCLAW_ROOT/$workspace_name"
    [ -d "$source_dir" ] || continue
    if [ ! -f "$target_dir/SOUL.md" ]; then
      mkdir -p "$target_dir"
      cp -a "$source_dir"/. "$target_dir/"
      log_info "已初始化 $workspace_name"
    fi
  done
}

register_openclaw_agents() {
  log_info "向 Gateway 注册 agents..."
  local entry agent_name workspace_name workspace_path agents_list errf err
  agents_list="$(openclaw agents list 2>/dev/null || true)"
  errf="$(mktemp)"
  local spec="main:workspace arch:workspace-arch dev:workspace-dev manager:workspace-manager qa:workspace-qa sre:workspace-sre research:workspace-research"
  for entry in $spec; do
    agent_name="${entry%%:*}"
    workspace_name="${entry##*:}"
    workspace_path="$OPENCLAW_ROOT/$workspace_name"
    [ -d "$workspace_path" ] || continue
    if echo "$agents_list" | grep -qE "(^|[[:space:];,])${agent_name}([[:space:];,]|$)"; then
      log_info "agent 已注册，跳过: $agent_name"
      continue
    fi
    : >"$errf"
    if openclaw agents add "$agent_name" --workspace "$workspace_path" 2>"$errf"; then
      log_info "已注册 agent: $agent_name"
      agents_list="$(openclaw agents list 2>/dev/null || true)"
    else
      err="$(head -c 400 "$errf" 2>/dev/null | tr -d '\r\n')"
      if [ "$agent_name" = "main" ] && echo "$err" | grep -qiE 'already|exist|duplicate|default|internal|main'; then
        log_info "main 为 Gateway 内置或已存在，跳过 agents add"
      else
        log_warn "agents add 失败: $agent_name (${err:0:200})"
      fi
    fi
  done
  rm -f "$errf"
}

# openclaw agents add 会改写 openclaw.json，常把 channels.matrix / bindings / LLM 配置清掉或写回旧值，必须在注册之后重新合并。
finalize_openclaw_matrix_after_agents() {
  log_info "注册 agents 后重新合并 LLM、Matrix 路由与群组策略…"
  patch_openclaw_llm_from_env
  patch_bindings_if_room
  configure_matrix_channels
}

main() {
  log_info "========== OpenClaw 启动 =========="
  wait_for_synapse || exit 1
  warn_llm_api_key
  ensure_passwords
  bootstrap_matrix_accounts
  create_team_room_if_needed
  invite_all_team_members
  auto_accept_team_room_invites
  deploy_workspaces
  start_gateway || true
  generate_openclaw_json
  configure_matrix_channels
  register_openclaw_agents
  finalize_openclaw_matrix_after_agents
  log_info "========== 完成。Gateway :${OPENCLAW_PORT:-18789}；Matrix HS: ${SYNAPSE_ENDPOINT} =========="
  log_info "Human 登录: @${HUMAN_USERNAME}:${SYNAPSE_SERVER_NAME}（密码见 .env 的 HUMAN_PASSWORD）"
  exec tail -f /dev/null
}

main "$@"
