#!/bin/bash
# Claw Team 烟雾测试 (MVP 版本)
# 验证 Synapse + Element Web 服务是否正常启动

set -euo pipefail

# 配置
SYNAPSE_PORT="${SYNAPSE_PORT:-8008}"
ELEMENT_PORT="${ELEMENT_PORT:-10001}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 测试计数器
TESTS_PASSED=0
TESTS_FAILED=0

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

echo "=========================================="
echo "Claw Team 烟雾测试 (MVP)"
echo "=========================================="
echo ""

# -----------------------------------------------------------------------------
# Test 1: 检查 Docker 是否可用
# -----------------------------------------------------------------------------
log_info "[1/8] 检查 Docker..."
if docker --version > /dev/null 2>&1; then
    log_pass "Docker 可用: $(docker --version | cut -d' ' -f3 | tr -d ',')"
else
    log_fail "Docker 不可用"
fi

# -----------------------------------------------------------------------------
# Test 2: 检查 docker-compose 是否可用
# -----------------------------------------------------------------------------
log_info "[2/8] 检查 docker-compose..."
if docker compose version > /dev/null 2>&1; then
    log_pass "docker-compose 可用: $(docker compose version | cut -d' ' -f4 | tr -d ',')"
else
    log_fail "docker-compose 不可用"
fi

# -----------------------------------------------------------------------------
# Test 3: 检查 docker-compose 服务状态
# -----------------------------------------------------------------------------
log_info "[3/8] 检查服务启动状态..."
if docker compose ps --format "{{.Status}}" | grep -q "^Up"; then
    log_pass "至少一个服务已启动"
else
    log_fail "没有服务运行，请先运行 'make up'"
fi

# -----------------------------------------------------------------------------
# Test 4: Synapse 健康检查 (HTTP)
# -----------------------------------------------------------------------------
log_info "[4/8] 检查 Synapse Matrix 服务..."
if curl -sf "http://localhost:${SYNAPSE_PORT}/_matrix/client/versions" > /dev/null 2>&1; then
    log_pass "Synapse HTTP 端点正常"
else
    log_fail "Synapse 不可访问 (http://localhost:${SYNAPSE_PORT})"
fi

# -----------------------------------------------------------------------------
# Test 5: Element Web 健康检查 (HTTP)
# -----------------------------------------------------------------------------
log_info "[5/8] 检查 Element Web..."
if curl -sf "http://localhost:${ELEMENT_PORT}" > /dev/null 2>&1; then
    log_pass "Element Web 正常"
else
    log_fail "Element Web 不可访问 (http://localhost:${ELEMENT_PORT})"
fi

# -----------------------------------------------------------------------------
# Test 6: Synapse 容器健康状态
# -----------------------------------------------------------------------------
log_info "[6/8] 检查 Synapse 容器..."
if docker ps --format "{{.Names}} {{.Status}}" | grep -q "^clawteam-synapse.*Up"; then
    log_pass "Synapse 容器运行中"
else
    log_fail "Synapse 容器未运行"
fi

# -----------------------------------------------------------------------------
# Test 7: Element 容器健康状态
# -----------------------------------------------------------------------------
log_info "[7/8] 检查 Element 容器..."
if docker ps --format "{{.Names}} {{.Status}}" | grep -q "^clawteam-element.*Up"; then
    log_pass "Element 容器运行中"
else
    log_fail "Element 容器未运行"
fi

# -----------------------------------------------------------------------------
# Test 8: Docker 网络检查
# -----------------------------------------------------------------------------
log_info "[8/8] 检查 Docker 网络..."
if docker network inspect clawteam_clawteam-network > /dev/null 2>&1; then
    log_pass "Docker 网络存在"
else
    log_fail "Docker 网络不存在"
fi

# -----------------------------------------------------------------------------
# 测试总结
# -----------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "测试结果"
echo "=========================================="
echo -e "通过: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "失败: ${RED}${TESTS_FAILED}${NC}"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}所有烟雾测试通过!${NC}"
    echo ""
    echo "下一步:"
    echo "  1. 运行 'bash configs/matrix/init.sh' 初始化用户"
    echo "  2. 访问 Element Web (http://localhost:${ELEMENT_PORT})"
    echo "  3. 使用 @human 账号登录并测试"
    exit 0
else
    echo -e "${RED}部分测试失败，请检查上述问题${NC}"
    exit 1
fi
