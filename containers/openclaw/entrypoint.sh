#!/bin/bash
# OpenClaw 容器入口
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/matrix-init.sh"
source "$SCRIPT_DIR/lib/gateway-init.sh"
source "$SCRIPT_DIR/lib/config-gen.sh"
source "$SCRIPT_DIR/lib/agents-init.sh"

main() {
  log_info "========== OpenClaw 启动 =========="

  # 1. Matrix 初始化
  wait_for_homeserver || exit 1
  warn_llm_api_key
  ensure_passwords
  bootstrap_matrix_accounts
  create_team_room_if_needed
  invite_all_team_members
  auto_accept_team_room_invites

  # 2. Gateway
  deploy_workspaces
  start_gateway || true

  # 3. 配置与注册
  generate_openclaw_json
  configure_matrix_channels
  register_openclaw_agents
  finalize_after_agents

  log_info "========== 完成。Gateway :${OPENCLAW_PORT:-18789}; Matrix HS: ${MATRIX_HOMESERVER_URL} =========="
  log_info "Human 登录: @${HUMAN_USERNAME}:${MATRIX_SERVER_NAME}（密码见 .env）"
  exec tail -f /dev/null
}

main "$@"
