#!/bin/bash
# OpenClaw Agent Manager 初始化脚本
# 用于注册 Agent 用户到 Synapse Matrix 服务器

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
SYNAPSE_SERVER="${MATRIX_HOMESERVER:-http://localhost:8008}"
AGENT_ID="${OPENCLAW_AGENT_ID:-manager}"
AGENT_PASSWORD="${OPENCLAW_AGENT_PASSWORD}"
REGISTRATION_SHARED_SECRET="${OPENCLAW_REGISTRATION_SHARED_SECRET:-a-secret-key-change-in-production}"
ADMIN_USER="${OPENCLAW_ADMIN_USER:-synapse_admin}"
ADMIN_PASSWORD="${OPENCLAW_ADMIN_PASSWORD:-}"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    command -v curl >/dev/null 2>&1 || { log_error "curl is required but not installed."; exit 1; }
    command -v jq >/dev/null 2>&1 || { log_error "jq is required but not installed."; exit 1; }
}

# 检查环境变量
check_env() {
    if [[ -z "${AGENT_PASSWORD}" ]]; then
        log_error "OPENCLAW_AGENT_PASSWORD environment variable is not set"
        exit 1
    fi

    if [[ -z "${ADMIN_PASSWORD}" ]]; then
        log_warn "OPENCLAW_ADMIN_PASSWORD is not set, trying default"
    fi
}

# 注册 Agent 用户
register_agent() {
    log_info "Registering agent: ${AGENT_ID}"

    local nonce
    nonce=$(curl -s -X POST "${SYNAPSE_SERVER}/_synapse/admin/v1/register" \
        -H "Content-Type: application/json" \
        -d '{}' \
        2>/dev/null | jq -r '.nonce')

    if [[ -z "${nonce}" || "${nonce}" == "null" ]]; then
        log_error "Failed to get nonce from Synapse"
        exit 1
    fi

    log_info "Got nonce: ${nonce}"

    local response
    response=$(curl -s -X POST "${SYNAPSE_SERVER}/_synapse/admin/v1/register" \
        -H "Content-Type: application/json" \
        -d "{
            \"nonce\": \"${nonce}\",
            \"username\": \"${AGENT_ID}\",
            \"password\": \"${AGENT_PASSWORD}\",
            \"admin\": false,
            \"shared_secret\": \"${REGISTRATION_SHARED_SECRET}\"
        }")

    local user_id
    user_id=$(echo "${response}" | jq -r '.user_id')

    if [[ "${user_id}" == "null" || -z "${user_id}" ]]; then
        log_error "Failed to register agent. Response: ${response}"
        exit 1
    fi

    log_info "Successfully registered agent: ${user_id}"
}

# 验证注册
verify_registration() {
    log_info "Verifying registration..."

    local login_response
    login_response=$(curl -s -X POST "${SYNAPSE_SERVER}/_matrix/client/r0/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"identifier\": {
                \"type\": \"m.id.user\",
                \"user\": \"${AGENT_ID}\"
            },
            \"password\": \"${AGENT_PASSWORD}\",
            \"device_id\": \"openclaw-agent\"
        }")

    local access_token
    access_token=$(echo "${login_response}" | jq -r '.access_token')

    if [[ "${access_token}" == "null" || -z "${access_token}" ]]; then
        log_error "Failed to verify registration. Response: ${login_response}"
        exit 1
    fi

    log_info "Agent login successful"
}

# 主函数
main() {
    log_info "OpenClaw Agent Manager 初始化脚本"
    log_info "Synapse Server: ${SYNAPSE_SERVER}"

    check_dependencies
    check_env
    register_agent
    verify_registration

    log_info "初始化完成!"
}

main "$@"
