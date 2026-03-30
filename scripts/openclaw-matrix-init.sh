#!/bin/bash
# OpenClaw Matrix Channel 初始化脚本
# 用于配置 Agent 连接 Matrix

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SYNAPSE_SERVER="${OPENCLAW_MATRIX_HOMESERVER:-http://synapse:8008}"
AGENT_ID="${OPENCLAW_AGENT_ID:-openclaw-agent}"
AGENT_PASSWORD="${OPENCLAW_AGENT_PASSWORD:-}"
GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-}"

OPENCLAW_CONFIG_DIR="/home/node/.openclaw"
OPENCLAW_CONFIG_FILE="${OPENCLAW_CONFIG_DIR}/openclaw.json"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查环境变量
check_env() {
    if [[ -z "${AGENT_PASSWORD}" ]]; then
        log_error "OPENCLAW_AGENT_PASSWORD environment variable is not set"
        exit 1
    fi
}

# 启用 matrix 插件
enable_matrix_plugin() {
    log_info "启用 matrix 插件..."
    openclaw plugins enable matrix 2>&1 || true
}

# 配置 allowPrivateNetwork
configure_private_network() {
    log_info "配置 allowPrivateNetwork..."
    openclaw config set channels.matrix.allowPrivateNetwork true 2>&1
}

# 添加 Matrix channel
add_matrix_channel() {
    log_info "添加 Matrix channel 配置..."

    # 使用 openclaw channels add 命令添加配置
    openclaw channels add \
        --channel matrix \
        --homeserver "${SYNAPSE_SERVER}" \
        --user-id "@${AGENT_ID}:localhost" \
        --password "${AGENT_PASSWORD}" \
        --device-name openclaw-agent 2>&1
}

# 验证连接状态
verify_connection() {
    log_info "验证 Matrix channel 连接状态..."

    local status
    status=$(openclaw channels status 2>&1 | grep -i "matrix" || echo "")

    if echo "$status" | grep -q "running"; then
        log_info "Matrix channel 状态: running ✅"
        return 0
    else
        log_warn "Matrix channel 状态检查: $status"
        return 1
    fi
}

# 主函数
main() {
    log_info "OpenClaw Matrix Channel 初始化"
    log_info "Homeserver: ${SYNAPSE_SERVER}"
    log_info "Agent ID: ${AGENT_ID}"

    check_env

    enable_matrix_plugin
    configure_private_network
    add_matrix_channel

    echo ""
    verify_connection

    log_info "初始化完成!"
}

main "$@"
