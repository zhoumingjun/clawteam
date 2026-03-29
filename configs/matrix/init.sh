#!/bin/bash
# Conduit Matrix 初始化脚本
# 用于创建 Agent 用户和 Team 房间

set -e

# 配置
CONDUIT_SERVER=${CONDUIT_SERVER:-http://localhost:10000}
ADMIN_SECRET=${CONDUIT_ADMIN_SECRET:-clawteam-secret-change-me}

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# 创建 Matrix 用户
create_user() {
    local username=$1
    local password=$2
    local admin=${3:-false}

    log_info "创建用户: @$username"

    local admin_flag=""
    if [ "$admin" = "true" ]; then
        admin_flag="-d '{\"admin\": true}'"
    fi

    local response=$(curl -s -X POST "$CONDUIT_SERVER/_synapse/admin/v2/register" \
        -H "Content-Type: application/json" \
        -d '{"username":"'"$username"'","password":"'"$password"'","admin":'"$admin"'}' 2>&1)

    if echo "$response" | grep -q "access_token"; then
        log_info "用户 $username 创建成功"
        return 0
    else
        # 尝试不重复创建
        if echo "$response" | grep -q "already"; then
            log_warn "用户 $username 已存在，跳过"
            return 0
        fi
        log_error "用户 $username 创建失败: $response"
        return 1
    fi
}

# 创建房间
create_room() {
    local room_id=$1
    local topic=${2:-""}
    local preset=${3:-"private_chat"}

    log_info "创建房间: $room_id"

    local response=$(curl -s -X POST "$CONDUIT_SERVER/_matrix/client/r0/createRoom" \
        -H "Content-Type: application/json" \
        -d '{
            "room_id":"'"$room_id"'",
            "topic":"'"$topic"'",
            "preset":"'"$preset"'",
            "invite":[],
            "creation_content":{"m.federate":false}
        }' 2>&1)

    if echo "$response" | grep -q "room_id"; then
        log_info "房间 $room_id 创建成功"
        return 0
    else
        if echo "$response" | grep -q "already"; then
            log_warn "房间 $room_id 已存在，跳过"
            return 0
        fi
        log_error "房间 $room_id 创建失败: $response"
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

    # 等待 Conduit 就绪
    wait_for_conduit || exit 1

    log_info ""
    log_info "----------------------------------------"
    log_info "创建 Agent 用户"
    log_info "----------------------------------------"

    # 创建 Agent 用户
    create_user "manager" "manager_password" true
    create_user "arch" "arch_password"
    create_user "dev" "dev_password"
    create_user "qa" "qa_password"
    create_user "sre" "sre_password"
    create_user "research" "research_password"

    log_info ""
    log_info "----------------------------------------"
    log_info "创建 Human 用户"
    log_info "----------------------------------------"

    create_user "human" "human_password"

    log_info ""
    log_info "----------------------------------------"
    log_info "创建 Team 房间"
    log_info "----------------------------------------"

    # 创建默认 Team 房间
    create_room "!claw-team:localhost:10000" "Claw Team 主房间"

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
    log_info "房间:"
    log_info "  - !claw-team:localhost:10000"
    log_info ""
    log_info "请通过 Element Web (http://localhost:10001) 登录"
}

# 运行
main "$@"
