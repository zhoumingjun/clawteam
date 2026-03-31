#!/bin/bash
# Agent workspace 部署、Gateway 注册、Matrix channel 配置

deploy_workspaces() {
  log_info "部署 workspace 模板..."
  local entry agent_name source_dir target_dir
  local spec="arch:arch dev:dev manager:manager qa:qa sre:sre research:research main:default"
  for entry in $spec; do
    agent_name="${entry%%:*}"
    local dir_name="${entry##*:}"
    source_dir="$OPENCLAW_SOURCE/$dir_name"
    target_dir="$OPENCLAW_ROOT/$dir_name"
    [ -d "$source_dir" ] || continue
    if [ ! -f "$target_dir/SOUL.md" ]; then
      mkdir -p "$target_dir"
      cp -a "$source_dir"/. "$target_dir/"
      log_info "已初始化 $dir_name"
    fi
  done
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
      --homeserver "$MATRIX_HOMESERVER_URL" \
      --access-token "$token"; then
      log_info "Matrix channel: $user"
    else
      log_warn "Matrix channel 添加失败: $user"
    fi
  done <"$TOKENS_FILE" || true
}

register_openclaw_agents() {
  log_info "向 Gateway 注册 agents..."
  local entry agent_name dir_name workspace_path agents_list errf err
  agents_list="$(openclaw agents list 2>/dev/null || true)"
  errf="$(mktemp)"
  local spec="main:default arch:arch dev:dev manager:manager qa:qa sre:sre research:research"
  for entry in $spec; do
    agent_name="${entry%%:*}"
    dir_name="${entry##*:}"
    workspace_path="$OPENCLAW_ROOT/$dir_name"
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

# openclaw agents add 会改写 openclaw.json，必须在注册之后重新合并配置
finalize_after_agents() {
  log_info "注册 agents 后重新合并 LLM、Matrix 路由与群组策略..."
  patch_openclaw_llm_from_env
  patch_bindings_if_room
  configure_matrix_channels
}
