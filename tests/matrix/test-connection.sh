#!/bin/bash
# Matrix 连接测试脚本
# 用于验证 OpenClaw Agent 能连接 Synapse 并响应消息

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SYNAPSE_SERVER="${MATRIX_SERVER:-http://localhost:8008}"
AGENT_USER="${OPENCLAW_AGENT_USER:-openclaw-agent}"
AGENT_PASSWORD="${OPENCLAW_AGENT_PASSWORD:-openclaw123}"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查 Agent Matrix channel 状态
check_channel_status() {
    log_info "检查 OpenClaw Agent Matrix channel 状态..."
    local status
    status=$(docker exec clawteam-openclaw-agent-manager openclaw channels status 2>&1 | grep -i "matrix" || echo "")

    if echo "$status" | grep -q "running"; then
        log_info "Matrix channel 状态: running ✅"
        return 0
    else
        log_error "Matrix channel 未运行: $status"
        return 1
    fi
}

# 验证 Agent 用户登录
verify_agent_login() {
    log_info "验证 Agent 用户登录..."

    local response
    response=$(curl -s -X POST "${SYNAPSE_SERVER}/_matrix/client/r0/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"m.login.password\",
            \"identifier\": {\"type\": \"m.id.user\", \"user\": \"${AGENT_USER}\"},
            \"password\": \"${AGENT_PASSWORD}\",
            \"device_id\": \"test\"
        }")

    local access_token
    access_token=$(echo "$response" | jq -r '.access_token')

    if [[ "${access_token}" == "null" || -z "${access_token}" ]]; then
        log_error "Agent 登录失败: $(echo "$response" | jq -r '.error')"
        return 1
    fi

    log_info "Agent 登录成功 ✅"
    echo "$access_token"
}

# 主函数
main() {
    log_info "OpenClaw Agent Matrix 连接测试"
    echo ""

    # 1. 检查 channel 状态
    if ! check_channel_status; then
        log_error "Matrix channel 检查失败"
        exit 1
    fi

    echo ""

    # 2. 验证登录
    if ! verify_agent_login; then
        log_error "Agent 登录验证失败"
        exit 1
    fi

    echo ""
    log_info "所有检查通过！Agent 已成功连接到 Matrix ✅"
}

main "$@"
