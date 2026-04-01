#!/bin/bash
# 生成和维护 openclaw.json（LLM 配置、Matrix routing、agent bindings）

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
    log_warn "ANTHROPIC_API_KEY 长度过短，请检查 Key 与 MODEL_NAME 是否匹配你的供应商"
  fi
}

generate_openclaw_json() {
  mkdir -p "$OPENCLAW_ROOT"
  load_or_assign_room_id
  local room_id="${MATRIX_ROOM_ID:-}"

  if [ -f "$OPENCLAW_JSON" ]; then
    log_info "保留已有 openclaw.json，仅补充 Matrix routing"
  else
    log_info "生成 openclaw.json..."
    export OC_ROOM_ID="$room_id"
    export OC_HOMESERVER="$MATRIX_HOMESERVER_URL"
    export OC_SERVER_NAME="$MATRIX_SERVER_NAME"
    export OC_OUT="$OPENCLAW_JSON"
    node <<'NODE'
const fs = require('fs');
const roomId = process.env.OC_ROOM_ID || '';
const homeserver = process.env.OC_HOMESERVER;
const server = process.env.OC_SERVER_NAME || 'localhost';
const out = process.env.OC_OUT;
const ROLES = JSON.parse(process.env.OC_ROLES || '[]');
const apiKey = process.env.ANTHROPIC_API_KEY || '';
const model = process.env.MODEL_NAME || 'claude-sonnet-4-20250514';
const baseUrl = (process.env.ANTHROPIC_BASE_URL || '').trim();
const useMinimaxProvider = Boolean(baseUrl) && !/^claude-/i.test(model);
const mentionFor = (id) => {
  const cap = id.charAt(0).toUpperCase() + id.slice(1);
  return [
    `@${id}`, `@${cap}`,
    `@${id}:${server}`, `@${cap}:${server}`,
    `matrix.to/#/@${id}:${server}`,
  ];
};
const agents = [{ id: 'main', default: true, workspace: '/root/.openclaw/default' }];
for (const id of ROLES) {
  agents.push({
    id,
    workspace: `/root/.openclaw/${id}`,
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
      models: [{
        id: model, name: model, reasoning: true,
        input: ['text'], contextWindow: 200000, maxTokens: 8192,
      }],
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
      homeserver: homeserver,
      allowPrivateNetwork: true,
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
    match: { channel: 'matrix', accountId: agentId, peer: { kind: 'group', id: roomId } }
  }));
}
fs.writeFileSync(out, JSON.stringify(config, null, 2));
NODE
  fi

  patch_openclaw_llm_from_env
  patch_bindings_if_room
}

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
    baseUrl: baseUrl.replace(/\\/\$/, ''),
    api: 'anthropic-messages',
    apiKey,
    models: [{
      id: model, name: model, reasoning: true,
      input: ['text'], contextWindow: 200000, maxTokens: 8192,
    }],
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
    log_info "同步团队房间与 Matrix 多账号 bindings..."
  else
    log_info "无 MATRIX_ROOM_ID：仅补充 channels.matrix 基础配置"
  fi
  node -e "
const fs = require('fs');
const ROLES = JSON.parse(process.env.OC_ROLES || '[]');
const f = process.argv[1];
const roomId = process.argv[2] || '';
const homeserver = process.argv[3];
const server = process.argv[4];
const mentionFor = (id) => {
  const cap = id.charAt(0).toUpperCase() + id.slice(1);
  return ['@' + id, '@' + cap, '@' + id + ':' + server, '@' + cap + ':' + server, 'matrix.to/#/@' + id + ':' + server];
};
let c = JSON.parse(fs.readFileSync(f, 'utf8'));
if (!c.channels) c.channels = {};
if (!c.channels.matrix) c.channels.matrix = { enabled: true, homeserver: homeserver, allowPrivateNetwork: true, groupPolicy: 'allowlist', groups: {} };
c.channels.matrix.homeserver = homeserver;
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
    if (!a) { a = { id, workspace: '/root/.openclaw/' + id }; list.push(a); }
    a.groupChat = { mentionPatterns: mentionFor(id) };
  }
  const main = list.find((a) => a.id === 'main');
  if (main && main.groupChat) delete main.groupChat;
  c.agents = c.agents || {};
  c.agents.list = list;
}
fs.writeFileSync(f, JSON.stringify(c, null, 2));
" "$OPENCLAW_JSON" "$room" "$MATRIX_HOMESERVER_URL" "$MATRIX_SERVER_NAME"
}
