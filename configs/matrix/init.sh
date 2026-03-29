#!/bin/bash
# Conduit Matrix 初始化脚本
# 使用 Matrix Client-Server API (/_matrix/client/r0/register)
# 密码从环境变量读取，不硬编码

set -e

# 配置
CONDUIT_SERVER=${CONDUIT_SERVER:-http://localhost:10000}
ADMIN_SECRET=${CONDUIT_ADMIN_SECRET:-}

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 等待 Conduit 就绪
wait_for_conduit() {
    log_info "等待 Conduit 服务就绪..."
    local max_attempts=30
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$CONDUIT_SERVER/_matrix/client/versions" > /dev/null 2>&1; then
            log_info "Conduit 服务已就绪"
            return 0
        fi
        log_info "等待中... ($attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    log_error "Conduit 服务启动超时"
    return 1
}

# 创建 Matrix 用户 (使用标准 Client-Server API)
# Conduit 不支持自定义 room_id，让服务器自动生成
create_user() {
    local username=$1
    local password=$2

    log_info "创建用户: @$username"

    local response=$(curl -s -X POST "$CONDUIT_SERVER/_matrix/client/r0/register" \
        -H "Content-Type: application/json" \
        -d '{
            "auth": {"type": "m.login.dummy"},
            "username": "'"$username"'",
            "password": "'"$password"'"
        }' 2>&1)

    if echo "$response" | grep -q "access_token"; then
        log_info "用户 $username 创建成功"
        return 0
    else
        # 尝试不重复创建 (M_USER_IN_USE)
        if echo "$response" | grep -q "M_USER_IN_USE"; then
            log_warn "用户 $username 已存在，跳过"
            return 0
        fi
        log_error "用户 $username 创建失败: $response"
        return 1
    fi
}

# 主函数
main() {
    log_info "=========================================="
    log_info "Claw Team Matrix 初始化"
    log_info "=========================================="
    log_info "服务器: $CONDUIT_SERVER"
    log_info ""

    # 检查环境变量
    if [ -z "$MANAGER_PASSWORD" ]; then
        log_warn "MANAGER_PASSWORD 未设置，使用默认值 (仅用于开发)"
        MANAGER_PASSWORD="manager_password"
    fi

    # 等待 Conduit 就绪
    wait_for_conduit || exit 1

    log_info ""
    log_info "----------------------------------------"
    log_info "创建 Agent 用户"
    log_info "----------------------------------------"

    # 创建 Agent 用户
    create_user "manager" "${MANAGER_PASSWORD}"
    create_user "arch" "${ARCH_PASSWORD:-arch_password}"
    create_user "dev" "${DEV_PASSWORD:-dev_password}"
    create_user "qa" "${QA_PASSWORD:-qa_password}"
    create_user "sre" "${SRE_PASSWORD:-sre_password}"
    create_user "research" "${RESEARCH_PASSWORD:-research_password}"

    log_info ""
    log_info "----------------------------------------"
    log_info "创建 Human 用户"
    log_info "----------------------------------------"

    create_user "human" "${HUMAN_PASSWORD:-human_password}"

    log_info ""
    log_info "=========================================="
    log_info "初始化完成!"
    log_info "=========================================="
    log_info ""
    log_info "Agent 用户:"
    log_info "  - @manager (管理员)"
    log_info "  - @arch, @dev, @qa, @sre, @research"
    log_info ""
    log_info "Human 用户:"
    log_info "  - @human"
    log_info ""
    log_info "请通过 Element Web (http://localhost:10001) 登录"
    log_info ""
    log_info "提示: 使用环境变量设置密码:"
    log_info "  MANAGER_PASSWORD, ARCH_PASSWORD, DEV_PASSWORD,"
    log_info "  QA_PASSWORD, SRE_PASSWORD, RESEARCH_PASSWORD,"
    log_info "  HUMAN_PASSWORD"
}

# 运行
main "$@"
