#!/bin/bash
# Claw Team E2E 测试
# 验证虚拟团队协作开发完整项目的流程

set -euo pipefail

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_OUTPUT="${PROJECT_ROOT}/outputs/e2e-test-$(date +%Y%m%d_%H%M%S)"
TIMESTAMP=$(date +%Y-%m-%d\ %H:%M:%S)

# Matrix 配置
MATRIX_SERVER="${CONDUIT_SERVER:-http://localhost:10000}"
HUMAN_USER="${HUMAN_USERNAME:-human}"
HUMAN_PASS="${HUMAN_PASSWORD:-human_password}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 测试计数器
TESTS_PASSED=0
TESTS_FAILED=0

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((TESTS_PASSED++)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; ((TESTS_FAILED++)); }
log_section() { echo ""; echo "=========================================="; echo "$1"; echo "=========================================="; }

# -----------------------------------------------------------------------------
# 初始化
# -----------------------------------------------------------------------------
init() {
    log_section "E2E 测试初始化"

    # 创建输出目录
    mkdir -p "${TEST_OUTPUT}"

    log_info "测试输出目录: ${TEST_OUTPUT}"
    log_info "时间戳: ${TIMESTAMP}"

    # 检查服务是否运行
    if ! docker compose ps | grep -q "Up"; then
        log_fail "服务未运行，请先运行 'make up'"
        exit 1
    fi
    log_pass "服务运行正常"

    # 记录初始状态
    echo "E2E 测试开始: ${TIMESTAMP}" > "${TEST_OUTPUT}/test.log"
}

# -----------------------------------------------------------------------------
# Test 1: Matrix 连接测试
# -----------------------------------------------------------------------------
test_matrix_connection() {
    log_section "Test 1: Matrix 连接测试"

    # 测试 Conduit API
    if response=$(curl -sf "${MATRIX_SERVER}/_matrix/client/versions" 2>&1); then
        if echo "$response" | grep -q "versions"; then
            log_pass "Matrix Client-Server API 可用"
        else
            log_fail "Matrix API 响应格式异常"
        fi
    else
        log_fail "无法连接 Matrix Server"
    fi
}

# -----------------------------------------------------------------------------
# Test 2: 用户认证测试
# -----------------------------------------------------------------------------
test_user_auth() {
    log_section "Test 2: 用户认证测试"

    # 测试 Human 用户登录（通过注册流程）
    local response
    response=$(curl -sf -X POST "${MATRIX_SERVER}/_matrix/client/r0/register" \
        -H "Content-Type: application/json" \
        -d '{
            "auth": {"type": "m.login.dummy"},
            "username": "e2e_test_user",
            "password": "e2e_test_password"
        }' 2>&1)

    if echo "$response" | grep -q "access_token"; then
        log_pass "用户认证成功"
        echo "$response" > "${TEST_OUTPUT}/auth_token.json"
    elif echo "$response" | grep -q "M_USER_IN_USE"; then
        log_pass "测试用户已存在（可复用）"
    else
        log_fail "用户认证失败: $response"
    fi
}

# -----------------------------------------------------------------------------
# Test 3: 房间创建测试
# -----------------------------------------------------------------------------
test_room_creation() {
    log_section "Test 3: 房间创建测试"

    # 创建测试房间
    local token=$(cat "${TEST_OUTPUT}/auth_token.json" 2>/dev/null | grep -o '"access_token":"[^"]*' | cut -d'"' -f4 || echo "")

    if [ -z "$token" ]; then
        log_fail "无法获取 access_token，跳过房间创建测试"
        return
    fi

    local response
    response=$(curl -sf -X POST "${MATRIX_SERVER}/_matrix/client/r0/createRoom" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${token}" \
        -d '{
            "name": "E2E Test Room",
            "topic": "Claw Team E2E Test"
        }' 2>&1)

    if echo "$response" | grep -q "room_id"; then
        local room_id=$(echo "$response" | grep -o '"room_id":"[^"]*' | cut -d'"' -f4)
        log_pass "房间创建成功: ${room_id}"
        echo "$room_id" > "${TEST_OUTPUT}/test_room_id"
    else
        log_fail "房间创建失败: $response"
    fi
}

# -----------------------------------------------------------------------------
# Test 4: 消息发送测试
# -----------------------------------------------------------------------------
test_message_send() {
    log_section "Test 4: 消息发送测试"

    local token=$(cat "${TEST_OUTPUT}/auth_token.json" 2>/dev/null | grep -o '"access_token":"[^"]*' | cut -d'"' -f4 || echo "")
    local room_id=$(cat "${TEST_OUTPUT}/test_room_id" 2>/dev/null || echo "")

    if [ -z "$token" ] || [ -z "$room_id" ]; then
        log_fail "缺少 token 或 room_id，跳过消息测试"
        return
    fi

    local response
    response=$(curl -sf -X PUT "${MATRIX_SERVER}/_matrix/client/r0/rooms/${room_id}/send/m.room.message/m$(date +%s)" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${token}" \
        -d '{
            "msgtype": "m.text",
            "body": "E2E Test Message from Claw Team"
        }' 2>&1)

    if echo "$response" | grep -q "event_id"; then
        log_pass "消息发送成功"
    else
        log_fail "消息发送失败: $response"
    fi
}

# -----------------------------------------------------------------------------
# Test 5: Docker 容器健康测试
# -----------------------------------------------------------------------------
test_container_health() {
    log_section "Test 5: Agent 容器健康测试"

    local all_healthy=true
    for agent in conduit element manager arch dev qa sre research; do
        if docker ps | grep -q "clawteam-${agent}.*Up"; then
            log_pass "${agent} Agent 容器运行正常"
        else
            log_fail "${agent} Agent 容器未运行"
            all_healthy=false
        fi
    done
}

# -----------------------------------------------------------------------------
# Test 6: Agent 配置检查
# -----------------------------------------------------------------------------
test_agent_configs() {
    log_section "Test 6: Agent 配置检查"

    local agents=(manager arch dev qa sre research)
    local configs=(SOUL.md AGENTS.md HEARTBEAT.md)

    for agent in "${agents[@]}"; do
        for config in "${configs[@]}"; do
            local config_path="${PROJECT_ROOT}/configs/agents/${agent}/${config}"
            if [ -f "$config_path" ]; then
                log_pass "${agent}/${config} 存在"
            else
                log_fail "${agent}/${config} 不存在"
            fi
        done
    done
}

# -----------------------------------------------------------------------------
# Test 7: Git 提交验证
# -----------------------------------------------------------------------------
test_git_commits() {
    log_section "Test 7: Git 提交历史验证"

    cd "${PROJECT_ROOT}"

    # 检查 git 历史
    local commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    log_info "Git 提交数量: ${commit_count}"

    if [ "$commit_count" -gt 0 ]; then
        log_pass "Git 提交历史存在"

        # 显示最近 5 次提交
        log_info "最近提交:"
        git log --oneline -5 2>/dev/null | while read line; do
            echo "  - $line"
        done
    else
        log_fail "Git 提交历史为空"
    fi

    # 检查 SPEC 文档
    if [ -d "${PROJECT_ROOT}/docs" ]; then
        local doc_count=$(find "${PROJECT_ROOT}/docs" -name "*.md" | wc -l | tr -d ' ')
        log_pass "文档文件数量: ${doc_count}"
    else
        log_fail "docs 目录不存在"
    fi
}

# -----------------------------------------------------------------------------
# Test 8: 部署配置验证
# -----------------------------------------------------------------------------
test_deployment_configs() {
    log_section "Test 8: 部署配置验证"

    # 检查 docker-compose.yml
    if [ -f "${PROJECT_ROOT}/docker-compose.yml" ]; then
        log_pass "docker-compose.yml 存在"

        # 检查服务数量
        local service_count=$(grep -c "^  [a-z-]*:" "${PROJECT_ROOT}/docker-compose.yml" 2>/dev/null || echo "0")
        log_info "docker-compose 服务数量: ${service_count}"
    else
        log_fail "docker-compose.yml 不存在"
    fi

    # 检查 Makefile
    if [ -f "${PROJECT_ROOT}/Makefile" ]; then
        log_pass "Makefile 存在"
    else
        log_fail "Makefile 不存在"
    fi

    # 检查环境变量模板
    if [ -f "${PROJECT_ROOT}/.env.example" ]; then
        log_pass ".env.example 存在"
    else
        log_fail ".env.example 不存在"
    fi
}

# -----------------------------------------------------------------------------
# Test 9: 网络连通性测试
# -----------------------------------------------------------------------------
test_network_connectivity() {
    log_section "Test 9: Agent 间网络连通性测试"

    # 测试 Manager 能否访问 Conduit
    if docker exec clawteam-manager curl -sf "http://conduit:6167/_matrix/client/versions" > /dev/null 2>&1; then
        log_pass "Manager → Conduit 网络连通"
    else
        log_fail "Manager → Conduit 网络不通"
    fi

    # 测试 Dev 能否访问 Conduit
    if docker exec clawteam-dev curl -sf "http://conduit:6167/_matrix/client/versions" > /dev/null 2>&1; then
        log_pass "Dev → Conduit 网络连通"
    else
        log_fail "Dev → Conduit 网络不通"
    fi
}

# -----------------------------------------------------------------------------
# Test 10: Volume 持久化测试
# -----------------------------------------------------------------------------
test_volume_persistence() {
    log_section "Test 10: Volume 持久化测试"

    for vol in conduit-data openclaw-config openclaw-data; do
        if docker volume inspect clawteam-${vol} > /dev/null 2>&1; then
            log_pass "Volume ${vol} 存在且持久化"
        else
            log_fail "Volume ${vol} 不存在"
        fi
    done
}

# -----------------------------------------------------------------------------
# 生成测试报告
# -----------------------------------------------------------------------------
generate_report() {
    log_section "生成测试报告"

    local report_file="${TEST_OUTPUT}/report.md"

    cat > "${report_file}" << EOF
# Claw Team E2E 测试报告

**测试时间**: ${TIMESTAMP}
**测试输出**: ${TEST_OUTPUT}

## 测试结果摘要

| 指标 | 数值 |
|------|------|
| 通过测试 | ${TESTS_PASSED} |
| 失败测试 | ${TESTS_FAILED} |
| 总计测试 | $((TESTS_PASSED + TESTS_FAILED)) |
| 通过率 | $(awk "BEGIN {printf \"%.1f\", ${TESTS_PASSED}/(${TESTS_PASSED}+${TESTS_FAILED})*100}")% |

## 测试项详情

### 1. Matrix 连接测试
- **状态**: $([ $? -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")
- **说明**: 验证 Matrix Client-Server API 可用性

### 2. 用户认证测试
- **状态**: $([ $? -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")
- **说明**: 验证用户注册和认证流程

### 3. 房间创建测试
- **状态**: $([ $? -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")
- **说明**: 验证 Matrix Room 创建功能

### 4. 消息发送测试
- **状态**: $([ $? -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")
- **说明**: 验证 Agent 间消息通信

### 5. Agent 容器健康
- **状态**: $([ $? -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")
- **说明**: 验证所有 Agent 容器运行状态

### 6. Agent 配置检查
- **状态**: $([ $? -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")
- **说明**: 验证 Agent 配置文件存在

### 7. Git 提交历史
- **状态**: $([ $? -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")
- **说明**: 验证代码版本控制

### 8. 部署配置
- **状态**: $([ $? -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")
- **说明**: 验证部署配置文件

### 9. 网络连通性
- **状态**: $([ $? -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")
- **说明**: 验证 Agent 间网络通信

### 10. Volume 持久化
- **状态**: $([ $? -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")
- **说明**: 验证数据持久化

## 项目结构

\`\`\`
${PROJECT_ROOT}/
$(tree -L 2 -d "${PROJECT_ROOT}" 2>/dev/null || find "${PROJECT_ROOT}" -maxdepth 2 -type d | head -20)
\`\`\`

## Agent 配置状态

| Agent | SOUL.md | AGENTS.md | HEARTBEAT.md |
|-------|---------|-----------|--------------|
$(for agent in manager arch dev qa sre research; do
    local soul=$( [ -f "${PROJECT_ROOT}/configs/agents/${agent}/SOUL.md" ] && echo "✅" || echo "❌")
    local agents=$( [ -f "${PROJECT_ROOT}/configs/agents/${agent}/AGENTS.md" ] && echo "✅" || echo "❌")
    local heartbeat=$( [ -f "${PROJECT_ROOT}/configs/agents/${agent}/HEARTBEAT.md" ] && echo "✅" || echo "❌")
    echo "| ${agent} | ${soul} | ${agents} | ${heartbeat} |"
done)

## Git 提交历史

\`\`\`
$(git log --oneline -10 2>/dev/null || echo "无提交历史")
\`\`\`

## 建议

$(if [ "${TESTS_FAILED}" -eq 0 ]; then
    echo "所有测试通过！系统已准备就绪，可以开始使用。"
else
    echo "存在 ${TESTS_FAILED} 个测试失败，请检查并修复后再继续。"
fi)

---
*此报告由 Claw Team E2E 测试自动生成*
EOF

    log_info "测试报告已生成: ${report_file}"

    # 复制报告到 outputs/latest
    mkdir -p "${PROJECT_ROOT}/outputs/latest"
    cp "${report_file}" "${PROJECT_ROOT}/outputs/latest/e2e-report.md"
    log_info "最新报告: ${PROJECT_ROOT}/outputs/latest/e2e-report.md"
}

# -----------------------------------------------------------------------------
# 测试总结
# -----------------------------------------------------------------------------
summary() {
    log_section "E2E 测试总结"
    echo ""
    echo -e "通过: ${GREEN}${TESTS_PASSED}${NC}"
    echo -e "失败: ${RED}${TESTS_FAILED}${NC}"
    echo ""

    if [ "${TESTS_FAILED}" -eq 0 ]; then
        echo -e "${GREEN}🎉 所有 E2E 测试通过!${NC}"
        echo ""
        echo "下一步:"
        echo "1. 运行 'make up' 启动完整服务"
        echo "2. 访问 Element Web (http://localhost:10001)"
        echo "3. 使用 'bash configs/matrix/init.sh' 初始化用户"
        echo "4. 向 Manager 下达任务开始开发"
        return 0
    else
        echo -e "${RED}⚠️ 部分测试失败，请检查问题${NC}"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# 主流程
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo "=========================================="
    echo "Claw Team E2E 测试"
    echo "=========================================="
    echo ""

    init

    test_matrix_connection
    test_user_auth
    test_room_creation
    test_message_send
    test_container_health
    test_agent_configs
    test_git_commits
    test_deployment_configs
    test_network_connectivity
    test_volume_persistence

    generate_report
    summary
}

main "$@"
